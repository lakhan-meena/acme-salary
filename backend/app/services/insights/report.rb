module Insights
  class Report
    CURRENT = Employee::CURRENT_STATUSES
    TENURE_ORDER = [ "Under 1 year", "1–3 years", "3–6 years", "6+ years" ].freeze
    MIN_SAMPLE = 20

    def to_h
      current = Employee.where(status: CURRENT)
      full_time = current.where(employment_type: "full_time")
      workforce_counts = Employee.group(:status).count
      active = workforce_counts.fetch("active", 0)
      on_leave = workforce_counts.fetch("on_leave", 0)
      terminated = workforce_counts.fetch("terminated", 0)

      ft_rows = full_time.pluck(:country_code, :department, :job_level, :gender, :hire_date, :base_salary_usd)
      bases = ft_rows.map { |row| row[5].to_f }
      mix = pay_mix(current)
      payroll = mix[:base_usd] + mix[:bonus_usd] + mix[:allowance_usd]
      bands = band_counts(full_time)
      by_country = country_rows(current, ft_rows)
      by_department = department_rows(current, ft_rows)
      by_level = level_rows(ft_rows)
      equity = equity_rows(ft_rows)
      tenure = tenure_rows(ft_rows)

      data = {
        note: "Payroll totals include active and on-leave employees of every type. Level, gender, tenure, and band figures use full-time employees only. USD amounts use the snapshot exchange rate stored on each person. This dataset is synthetic.",
        workforce: {
          active: active,
          on_leave: on_leave,
          terminated: terminated,
          current: active + on_leave
        },
        kpis: {
          annual_payroll_usd: payroll.round(2),
          median_base_usd: median(bases).round(2),
          average_base_usd: bases.empty? ? 0 : (bases.sum / bases.size).round(2),
          full_time_count: ft_rows.size,
          outside_band_count: bands[:below] + bands[:above],
          outside_band_rate: rate(bands[:below] + bands[:above], bands[:full_time])
        },
        by_country: by_country,
        by_department: by_department,
        by_level: by_level,
        pay_mix: mix.merge(total_usd: payroll.round(2)),
        pay_equity: equity,
        bands: bands,
        tenure: tenure
      }
      data[:headline] = headline(data)
      data[:questions] = questions(data)
      data
    end

    private

    def pay_mix(current)
      base, bonus, allowance = current.pick(
        Arel.sql("COALESCE(SUM(base_salary_usd), 0)"),
        Arel.sql("COALESCE(SUM(base_salary_annual * (bonus_target_percent / 100.0) * fx_rate_to_usd), 0)"),
        Arel.sql("COALESCE(SUM(annual_allowance * fx_rate_to_usd), 0)")
      )
      {
        base_usd: base.to_f.round(2),
        bonus_usd: bonus.to_f.round(2),
        allowance_usd: allowance.to_f.round(2)
      }
    end

    def country_rows(current, ft_rows)
      sums = current.group(:country_code).pluck(
        :country_code,
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(SUM(total_cash_usd), 0)")
      )
      medians = medians_by(ft_rows, 0, 5)
      total_payroll = sums.sum { |_, _, payroll| payroll.to_f }
      sums.map do |code, count, payroll|
        country = Compensation::Catalog.country(code)
        {
          country_code: code,
          label: country[:name],
          currency: country[:currency],
          headcount: count,
          payroll_usd: payroll.to_f.round(2),
          share: rate(payroll, total_payroll),
          median_base_usd: medians.fetch(code, 0).round(2)
        }
      end.sort_by { |row| -row[:payroll_usd] }
    end

    def department_rows(current, ft_rows)
      sums = current.group(:department).pluck(
        :department,
        Arel.sql("COUNT(*)"),
        Arel.sql("COALESCE(SUM(total_cash_usd), 0)")
      )
      medians = medians_by(ft_rows, 1, 5)
      total_payroll = sums.sum { |_, _, payroll| payroll.to_f }
      sums.map do |department, count, payroll|
        {
          label: department,
          headcount: count,
          payroll_usd: payroll.to_f.round(2),
          share: rate(payroll, total_payroll),
          median_base_usd: medians.fetch(department, 0).round(2)
        }
      end.sort_by { |row| -row[:payroll_usd] }
    end

    def level_rows(ft_rows)
      grouped = ft_rows.group_by { |row| row[2] }
      Compensation::Catalog::LEVEL_ORDER.filter_map do |level|
        values = (grouped[level] || []).map { |row| row[5].to_f }
        next if values.empty?

        {
          label: level,
          headcount: values.size,
          median_base_usd: median(values).round(2),
          average_base_usd: (values.sum / values.size).round(2)
        }
      end
    end

    def equity_rows(ft_rows)
      grouped = Hash.new { |hash, key| hash[key] = [] }
      ft_rows.each { |row| grouped[[ row[2], row[3] ]] << row[5].to_f }

      levels = Compensation::Catalog::LEVEL_ORDER.filter_map do |level|
        women = grouped[[ level, "female" ]]
        men = grouped[[ level, "male" ]]
        next if women.empty? && men.empty?

        entry = {
          label: level,
          women_count: women.size,
          men_count: men.size,
          women_median: women.empty? ? nil : median(women).round(2),
          men_median: men.empty? ? nil : median(men).round(2),
          non_binary_count: grouped[[ level, "non_binary" ]].size,
          undisclosed_count: grouped[[ level, "undisclosed" ]].size
        }
        if women.size >= MIN_SAMPLE && men.size >= MIN_SAMPLE && entry[:men_median].to_f.positive?
          entry[:gap] = ((entry[:women_median] - entry[:men_median]) / entry[:men_median]).round(4)
        end
        entry
      end

      comparable = levels.select { |row| row[:gap] }
      weight = comparable.sum { |row| row[:women_count] + row[:men_count] }
      weighted_gap = if weight.zero?
        nil
      else
        (comparable.sum { |row| row[:gap] * (row[:women_count] + row[:men_count]) } / weight).round(4)
      end

      { weighted_gap: weighted_gap, min_sample: MIN_SAMPLE, levels: levels }
    end

    def band_counts(full_time)
      joined = full_time.joins(<<~SQL.squish)
        INNER JOIN salary_bands
          ON salary_bands.country_code = employees.country_code
         AND salary_bands.job_level = employees.job_level
      SQL
      below = joined.where("employees.base_salary_annual < salary_bands.min_salary").count
      above = joined.where("employees.base_salary_annual > salary_bands.max_salary").count
      total = full_time.count
      { below: below, above: above, in_band: total - below - above, full_time: total }
    end

    def tenure_rows(ft_rows)
      today = Date.current
      grouped = Hash.new { |hash, key| hash[key] = [] }
      ft_rows.each { |row| grouped[tenure_label(row[4], today)] << row[5].to_f }
      TENURE_ORDER.map do |label|
        values = grouped[label]
        {
          label: label,
          headcount: values.size,
          median_base_usd: values.empty? ? 0 : median(values).round(2)
        }
      end
    end

    def tenure_label(hire_date, today)
      years = (today - hire_date).to_f / 365.25
      if years < 1
        "Under 1 year"
      elsif years < 3
        "1–3 years"
      elsif years < 6
        "3–6 years"
      else
        "6+ years"
      end
    end

    def questions(data)
      [
        country_question(data),
        department_question(data),
        level_question(data),
        mix_question(data),
        equity_question(data),
        band_question(data),
        tenure_question(data)
      ]
    end

    def country_question(data)
      rows = data[:by_country]
      top = rows.first
      second = rows.second
      answer = if top.nil?
        "There are no current employees to total."
      elsif second.nil?
        "#{top[:label]} is the only payroll country, at #{usd(top[:payroll_usd])}."
      else
        "#{top[:label]} is the largest payroll at #{usd(top[:payroll_usd])} (#{points(top[:share])} of target cash). #{second[:label]} is next at #{usd(second[:payroll_usd])}."
      end
      question("payroll_by_country", "Where does ACME's payroll go?", answer, bar_chart(rows, :payroll_usd))
    end

    def department_question(data)
      rows = data[:by_department]
      top = rows.first
      answer = if top.nil?
        "There are no current employees to total."
      else
        "#{top[:label]} is the most expensive department at #{usd(top[:payroll_usd])}, #{points(top[:share])} of target cash across #{number(top[:headcount])} people."
      end
      question("cost_by_department", "Which departments cost the most?", answer, bar_chart(rows, :payroll_usd))
    end

    def level_question(data)
      rows = data[:by_level]
      ic1 = rows.find { |row| row[:label] == "IC1" }
      ic6 = rows.find { |row| row[:label] == "IC6" }
      m4 = rows.find { |row| row[:label] == "M4" }
      answer = if ic1 && ic6 && m4
        "Full-time median base moves from #{usd(ic1[:median_base_usd])} at IC1 to #{usd(ic6[:median_base_usd])} at IC6. M4 median base is #{usd(m4[:median_base_usd])}."
      else
        "Add full-time employees at IC1, IC6, and M4 to compare levels."
      end
      question("pay_by_level", "How does base pay scale with level?", answer, bar_chart(rows, :median_base_usd))
    end

    def mix_question(data)
      mix = data[:pay_mix]
      total = mix[:total_usd].to_f
      answer = "Base salary is #{points(rate(mix[:base_usd], total))} of target cash, target bonuses #{points(rate(mix[:bonus_usd], total))}, and allowances #{points(rate(mix[:allowance_usd], total))}. The bonus figure is a target percent, not cash already paid."
      question(
        "pay_mix",
        "What is the mix of base, bonus, and allowance?",
        answer,
        {
          kind: "mix",
          points: [
            { label: "Base", value: mix[:base_usd], share: rate(mix[:base_usd], total) },
            { label: "Target bonus", value: mix[:bonus_usd], share: rate(mix[:bonus_usd], total) },
            { label: "Allowance", value: mix[:allowance_usd], share: rate(mix[:allowance_usd], total) }
          ]
        }
      )
    end

    def equity_question(data)
      equity = data[:pay_equity]
      gap = equity[:weighted_gap]
      comparable = equity[:levels].select { |row| row[:gap] }
      answer = if gap.nil?
        "There are not enough full-time women and men at the same level to compare medians. A level is included once it has at least #{equity[:min_sample]} of each."
      else
        direction = gap.negative? ? "lower" : "higher"
        extreme = gap.negative? ? comparable.min_by { |row| row[:gap] } : comparable.max_by { |row| row[:gap] }
        extreme_direction = extreme[:gap].negative? ? "lower" : "higher"
        "Across comparable levels, women's median base is #{points(gap)} #{direction} than men's. The widest gap is at #{extreme[:label]}, where women are #{points(extreme[:gap])} #{extreme_direction}."
      end
      question(
        "pay_equity",
        "At the same level, how do women's and men's median base compare?",
        answer,
        {
          kind: "equity",
          points: equity[:levels].map do |row|
            {
              label: row[:label],
              women: row[:women_median],
              men: row[:men_median],
              gap: row[:gap]
            }
          end
        }
      )
    end

    def band_question(data)
      bands = data[:bands]
      outside = bands[:below] + bands[:above]
      answer = "#{number(outside)} full-time employees (#{points(rate(outside, bands[:full_time]))}) sit outside their country band: #{number(bands[:below])} below the minimum and #{number(bands[:above])} above the maximum."
      question(
        "outside_band",
        "Who is paid outside their salary band?",
        answer,
        {
          kind: "split",
          points: [
            { label: "Below", value: bands[:below] },
            { label: "In band", value: bands[:in_band] },
            { label: "Above", value: bands[:above] }
          ]
        },
        people_query: "band=outside"
      )
    end

    def tenure_question(data)
      rows = data[:tenure]
      newest = rows.first
      oldest = rows.last
      answer = if oldest[:median_base_usd] > newest[:median_base_usd]
        "Full-time median base is #{usd(newest[:median_base_usd])} in the first year and #{usd(oldest[:median_base_usd])} for people with 6 or more years at ACME."
      else
        "Tenure does not line up with a higher median. First-year full-time median base is #{usd(newest[:median_base_usd])}, against #{usd(oldest[:median_base_usd])} for people with 6 or more years."
      end
      question("tenure", "Does pay rise with tenure?", answer, bar_chart(rows, :median_base_usd))
    end

    def question(id, prompt, answer, chart, people_query: nil)
      { id: id, prompt: prompt, answer: answer, chart: chart, people_query: people_query }
    end

    def bar_chart(rows, value_key)
      {
        kind: "bar",
        unit: "usd",
        points: rows.map { |row| { label: row[:label], value: row[value_key], headcount: row[:headcount] } }
      }
    end

    def headline(data)
      workforce = data[:workforce]
      kpis = data[:kpis]
      "#{number(workforce[:current])} current employees. Target annual cash is #{usd(kpis[:annual_payroll_usd])}. Median full-time base is #{usd(kpis[:median_base_usd])}."
    end

    def medians_by(rows, key_index, value_index)
      grouped = Hash.new { |hash, key| hash[key] = [] }
      rows.each { |row| grouped[row[key_index]] << row[value_index].to_f }
      grouped.transform_values { |values| median(values) }
    end

    def median(values)
      sorted = values.sort
      return 0.0 if sorted.empty?

      mid = sorted.length / 2
      sorted.length.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
    end

    def rate(part, whole)
      return 0.0 if whole.to_f.zero?

      (part.to_f / whole.to_f).round(4)
    end

    def usd(amount)
      "$#{ActiveSupport::NumberHelper.number_to_delimited(amount.to_f.round)}"
    end

    def number(amount)
      ActiveSupport::NumberHelper.number_to_delimited(amount.to_i)
    end

    def points(rate)
      "#{(rate.to_f.abs * 100).round(1)}%"
    end
  end
end
