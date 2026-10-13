module Compensation
  class Seeder
    PART_TIME_FACTOR = BigDecimal("0.6")

    def call
      Catalog.check!
      rng = Random.new(20261013)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      ActiveRecord::Base.transaction do
        CompensationChange.delete_all
        Employee.delete_all
        SalaryBand.delete_all
        User.delete_all

        seed_user
        seed_bands
        seed_employees(rng)
      end

      elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(1)
      puts "Seeded #{Employee.count} employees, #{SalaryBand.count} bands, #{CompensationChange.count} prior pay changes in #{elapsed}s"
    end

    private

    def seed_user
      User.create!(
        name: "HR Manager",
        email: "hr.manager@acme.test",
        password: "acme-hr-demo"
      )
    end

    def seed_bands
      now = Time.current
      rows = Catalog::COUNTRIES.flat_map do |country|
        Catalog::LEVEL_ORDER.map do |level|
          band = Catalog.band_for(country[:code], level)
          {
            country_code: country[:code],
            country_name: country[:name],
            job_level: level,
            currency: band[:currency],
            min_salary: band[:min],
            mid_salary: band[:mid],
            max_salary: band[:max],
            created_at: now,
            updated_at: now
          }
        end
      end
      SalaryBand.insert_all!(rows)
    end

    def seed_employees(rng)
      countries = Catalog::COUNTRIES.flat_map { |country| [ country ] * country[:count] }.shuffle(random: rng)
      departments = Catalog::DEPARTMENT_COUNTS.flat_map { |name, count| [ name ] * count }.shuffle(random: rng)
      levels = Catalog::LEVEL_COUNTS.flat_map { |level, count| [ level ] * count }.shuffle(random: rng)
      now = Time.current
      history = []
      rows = []

      10_000.times do |index|
        country = countries[index]
        department = departments[index]
        level = levels[index]
        gender = pick(rng, [ [ "female", 46 ], [ "male", 46 ], [ "non_binary", 4 ], [ "undisclosed", 4 ] ])
        status = pick(rng, [ [ "active", 92 ], [ "on_leave", 4 ], [ "terminated", 4 ] ])
        employment_type = pick(rng, [ [ "full_time", 88 ], [ "part_time", 7 ], [ "contractor", 5 ] ])
        code = format("ACME-%05d", index + 1)
        first_name = Catalog::FIRST_NAMES[rng.rand(Catalog::FIRST_NAMES.length)]
        last_name = Catalog::LAST_NAMES[rng.rand(Catalog::LAST_NAMES.length)]
        band = Catalog.band_for(country[:code], level)
        base = annual_base(rng, band, gender, employment_type)
        bonus = bonus_percent(rng, level, employment_type)
        allowance = allowance_for(country, employment_type)
        usd = Calculator.usd_amounts(base: base, bonus_percent: bonus, allowance: allowance, fx: country[:fx_to_usd])
        hire_date = random_hire_date(rng)
        effective_on = pay_effective_on(rng, hire_date)

        rows << {
          employee_code: code,
          first_name: first_name,
          last_name: last_name,
          email: "#{first_name}.#{last_name}.#{code}@acme.test".downcase,
          country_code: country[:code],
          country_name: country[:name],
          city: country[:cities][rng.rand(country[:cities].length)],
          department: department,
          job_title: Catalog.title_for(department, level),
          job_level: level,
          employment_type: employment_type,
          gender: gender,
          hire_date: hire_date,
          status: status,
          currency: country[:currency],
          base_salary_annual: base,
          bonus_target_percent: bonus,
          annual_allowance: allowance,
          fx_rate_to_usd: country[:fx_to_usd].to_d,
          base_salary_usd: usd[:base_salary_usd],
          total_cash_usd: usd[:total_cash_usd],
          comp_effective_on: effective_on,
          created_at: now,
          updated_at: now
        }

        if employment_type == "full_time" && (effective_on - hire_date).to_i > 180 && (index % 23).zero?
          history << {
            employee_code: code,
            base_salary_before: (base / BigDecimal("1.08")).round(2),
            base_salary_after: base,
            bonus_before: bonus,
            bonus_after: bonus,
            allowance_before: allowance,
            allowance_after: allowance,
            currency: country[:currency],
            reason: "Annual review",
            effective_on: effective_on
          }
        end
      end

      rows.each_slice(2_000) { |slice| Employee.insert_all!(slice) }
      seed_history(history)
    end

    def seed_history(history)
      return if history.empty?

      ids = Employee.where(employee_code: history.map { |row| row[:employee_code] }).pluck(:employee_code, :id).to_h
      now = Time.current
      changes = history.map do |row|
        {
          employee_id: ids.fetch(row[:employee_code]),
          base_salary_before: row[:base_salary_before],
          base_salary_after: row[:base_salary_after],
          bonus_before: row[:bonus_before],
          bonus_after: row[:bonus_after],
          allowance_before: row[:allowance_before],
          allowance_after: row[:allowance_after],
          currency: row[:currency],
          reason: row[:reason],
          effective_on: row[:effective_on],
          created_at: now,
          updated_at: now
        }
      end
      CompensationChange.insert_all!(changes)
    end

    def annual_base(rng, band, gender, employment_type)
      mid = band[:mid].to_f
      return round_money(mid * (1.05 + rng.rand * 0.20)) if employment_type == "contractor"

      gender_factor = case gender
      when "female" then 0.94 + rng.rand * 0.045
      when "male" then 1.00 + rng.rand * 0.03
      else 0.97 + rng.rand * 0.05
      end
      amount = mid * (0.88 + rng.rand * 0.27) * gender_factor
      amount *= PART_TIME_FACTOR.to_f if employment_type == "part_time"

      if employment_type == "full_time"
        roll = rng.rand
        if roll < 0.03
          amount = band[:min].to_f * (0.60 + rng.rand * 0.15)
        elsif roll < 0.06
          amount = band[:max].to_f * (1.08 + rng.rand * 0.18)
        else
          amount = amount.clamp(band[:min].to_f * 1.01, band[:max].to_f * 0.99)
        end
      end

      round_money(amount)
    end

    def bonus_percent(rng, level, employment_type)
      return BigDecimal("0") if employment_type == "contractor"

      target = Catalog::LEVELS.fetch(level)[:bonus]
      round_money([ 0, target + rng.rand(-1.0..1.0) ].max)
    end

    def allowance_for(country, employment_type)
      return BigDecimal("0") if employment_type == "contractor"

      amount = country[:allowance].to_d
      amount = (amount * PART_TIME_FACTOR).round(2) if employment_type == "part_time"
      amount
    end

    def random_hire_date(rng)
      start_on = Date.new(2014, 1, 6)
      finish_on = Date.new(2026, 9, 1)
      start_on + rng.rand((finish_on - start_on).to_i + 1)
    end

    def pay_effective_on(rng, hire_date)
      review_start = Date.new(2025, 4, 1)
      review_end = Date.new(2026, 10, 1)
      return hire_date if hire_date >= review_start

      review_start + rng.rand((review_end - review_start).to_i + 1)
    end

    def pick(rng, items)
      total = items.sum { |_, weight| weight }
      cursor = rng.rand(total)
      items.each do |value, weight|
        return value if cursor < weight

        cursor -= weight
      end
      items.last.first
    end

    def round_money(amount)
      amount.to_d.round(2)
    end
  end
end
