module Compensation
  # Reference data for ACME's synthetic workforce. Headcount weights sum to 10,000.
  # Exchange rates are a fixed snapshot so country comparisons do not move under the HR manager.
  module Catalog
    LEVEL_ORDER = %w[IC1 IC2 IC3 IC4 IC5 IC6 M1 M2 M3 M4].freeze

    LEVELS = {
      "IC1" => { usd_mid: 52_000, bonus: 5 },
      "IC2" => { usd_mid: 72_000, bonus: 8 },
      "IC3" => { usd_mid: 98_000, bonus: 10 },
      "IC4" => { usd_mid: 130_000, bonus: 12 },
      "IC5" => { usd_mid: 168_000, bonus: 15 },
      "IC6" => { usd_mid: 215_000, bonus: 20 },
      "M1" => { usd_mid: 145_000, bonus: 15 },
      "M2" => { usd_mid: 185_000, bonus: 20 },
      "M3" => { usd_mid: 235_000, bonus: 25 },
      "M4" => { usd_mid: 300_000, bonus: 30 }
    }.freeze

    LEVEL_COUNTS = {
      "IC1" => 1200,
      "IC2" => 1800,
      "IC3" => 2200,
      "IC4" => 1600,
      "IC5" => 800,
      "IC6" => 400,
      "M1" => 1000,
      "M2" => 600,
      "M3" => 300,
      "M4" => 100
    }.freeze

    DEPARTMENT_COUNTS = {
      "Engineering" => 3200,
      "Sales" => 1400,
      "Customer Success" => 1000,
      "Operations" => 900,
      "Product" => 800,
      "Marketing" => 700,
      "Finance" => 600,
      "Data" => 500,
      "People" => 500,
      "Legal" => 400
    }.freeze

    TITLES = {
      "Engineering" => [
        "Associate Engineer", "Software Engineer", "Senior Software Engineer", "Staff Engineer",
        "Principal Engineer", "Distinguished Engineer", "Engineering Manager",
        "Senior Engineering Manager", "Director of Engineering", "VP of Engineering"
      ],
      "Product" => [
        "Associate Product Manager", "Product Manager", "Senior Product Manager", "Staff Product Manager",
        "Principal Product Manager", "Product Lead", "Group Product Manager",
        "Senior Group Product Manager", "Director of Product", "VP of Product"
      ],
      "Sales" => [
        "Sales Development Representative", "Account Executive", "Senior Account Executive",
        "Enterprise Account Executive", "Strategic Account Executive", "Sales Lead",
        "Sales Manager", "Senior Sales Manager", "Director of Sales", "VP of Sales"
      ],
      "Marketing" => [
        "Marketing Associate", "Marketing Specialist", "Senior Marketing Specialist", "Marketing Lead",
        "Principal Marketer", "Campaign Strategist", "Marketing Manager",
        "Senior Marketing Manager", "Director of Marketing", "VP of Marketing"
      ],
      "Finance" => [
        "Finance Analyst", "Financial Analyst", "Senior Financial Analyst", "Finance Lead",
        "Principal Analyst", "Finance Advisor", "Finance Manager",
        "Senior Finance Manager", "Director of Finance", "VP of Finance"
      ],
      "People" => [
        "People Coordinator", "People Partner", "Senior People Partner", "People Lead",
        "Principal People Partner", "People Advisor", "People Manager",
        "Senior People Manager", "Director of People", "VP of People"
      ],
      "Customer Success" => [
        "Support Associate", "Customer Success Manager", "Senior Customer Success Manager",
        "Customer Success Lead", "Principal Customer Success Manager", "Customer Success Architect",
        "CS Team Manager", "Senior CS Manager", "Director of Customer Success", "VP of Customer Success"
      ],
      "Operations" => [
        "Operations Associate", "Operations Specialist", "Senior Operations Specialist", "Operations Lead",
        "Principal Operations Specialist", "Operations Advisor", "Operations Manager",
        "Senior Operations Manager", "Director of Operations", "VP of Operations"
      ],
      "Legal" => [
        "Legal Assistant", "Counsel", "Senior Counsel", "Lead Counsel",
        "Principal Counsel", "Senior Principal Counsel", "Legal Manager",
        "Senior Legal Manager", "Director of Legal", "General Counsel"
      ],
      "Data" => [
        "Data Analyst", "Data Scientist", "Senior Data Scientist", "Staff Data Scientist",
        "Principal Data Scientist", "Distinguished Data Scientist", "Data Manager",
        "Senior Data Manager", "Director of Data", "VP of Data"
      ]
    }.freeze

    # factor scales the US-equivalent midpoint to the local market before converting currency.
    COUNTRIES = [
      { code: "IN", name: "India", currency: "INR", fx_to_usd: "0.012", factor: "0.35", count: 2800,
        cities: [ "Bengaluru", "Hyderabad", "Pune", "Mumbai", "Gurugram" ], allowance: 240_000 },
      { code: "US", name: "United States", currency: "USD", fx_to_usd: "1", factor: "1.00", count: 2200,
        cities: [ "San Francisco", "New York", "Austin", "Seattle", "Chicago" ], allowance: 6_000 },
      { code: "GB", name: "United Kingdom", currency: "GBP", fx_to_usd: "1.27", factor: "0.92", count: 800,
        cities: [ "London", "Manchester", "Edinburgh", "Bristol" ], allowance: 4_500 },
      { code: "DE", name: "Germany", currency: "EUR", fx_to_usd: "1.08", factor: "0.90", count: 700,
        cities: [ "Berlin", "Munich", "Hamburg", "Frankfurt" ], allowance: 4_000 },
      { code: "CA", name: "Canada", currency: "CAD", fx_to_usd: "0.73", factor: "0.88", count: 600,
        cities: [ "Toronto", "Vancouver", "Montreal", "Calgary" ], allowance: 5_000 },
      { code: "SG", name: "Singapore", currency: "SGD", fx_to_usd: "0.74", factor: "0.95", count: 500,
        cities: [ "Singapore" ], allowance: 6_000 },
      { code: "AU", name: "Australia", currency: "AUD", fx_to_usd: "0.66", factor: "0.90", count: 450,
        cities: [ "Sydney", "Melbourne", "Brisbane", "Perth" ], allowance: 6_000 },
      { code: "NL", name: "Netherlands", currency: "EUR", fx_to_usd: "1.08", factor: "0.93", count: 400,
        cities: [ "Amsterdam", "Rotterdam", "Utrecht" ], allowance: 4_000 },
      { code: "JP", name: "Japan", currency: "JPY", fx_to_usd: "0.0067", factor: "0.85", count: 400,
        cities: [ "Tokyo", "Osaka", "Yokohama" ], allowance: 360_000 },
      { code: "AE", name: "United Arab Emirates", currency: "AED", fx_to_usd: "0.272", factor: "0.80", count: 350,
        cities: [ "Dubai", "Abu Dhabi" ], allowance: 18_000 },
      { code: "BR", name: "Brazil", currency: "BRL", fx_to_usd: "0.18", factor: "0.42", count: 400,
        cities: [ "Sao Paulo", "Rio de Janeiro", "Belo Horizonte" ], allowance: 12_000 },
      { code: "MX", name: "Mexico", currency: "MXN", fx_to_usd: "0.055", factor: "0.40", count: 400,
        cities: [ "Mexico City", "Guadalajara", "Monterrey" ], allowance: 60_000 }
    ].freeze

    FIRST_NAMES = %w[
      Aarav Aditi Amir Ananya Andrei Aisha Beatriz Carlos Chen Diego Elena Emma Fatima Gabriel
      Hannah Hiroshi Ingrid James Jiya Jordan Kai Lakshmi Lena Luca Maria Maya Mei Nina Oliver
      Priya Quinn Rafael Rosa Sofia Theo Uma Valentina Wei Yara Zoe Noah Olivia Liam Noah
      Anika Rohan Sana Idris Leila Mateo Camila Hugo Freya Noor Arjun Divya Kenji Aiko Pablo
      Chiara Jonas Marta Yusuf Hana Elias Nora Samir Leila Nia Omar
    ].freeze

    LAST_NAMES = %w[
      Sharma Patel Singh Gupta Kapoor Nair Mehta Iyer Khan Garcia Silva Rossi Muller Schmidt
      Bernard Martin Chen Wang Kim Park Tanaka Sato Nguyen Ali Hassan Ibrahim Cohen Levi
      Smith Johnson Williams Brown Jones Martinez Anderson Taylor Thomas Moore Jackson White
      Harris Clark Lewis Walker Young Allen King Wright Lopez Hill Green Adams Baker Nelson
      Carter Mitchell Perez Roberts Turner Phillips Campbell Parker Evans Edwards Collins
    ].freeze

    def self.check!
      country_total = COUNTRIES.sum { |country| country[:count] }
      raise "Country counts sum to #{country_total}, expected 10000" unless country_total == 10_000
      dept_total = DEPARTMENT_COUNTS.values.sum
      raise "Department counts sum to #{dept_total}, expected 10000" unless dept_total == 10_000
      level_total = LEVEL_COUNTS.values.sum
      raise "Level counts sum to #{level_total}, expected 10000" unless level_total == 10_000
      raise "Level order mismatch" unless LEVEL_COUNTS.keys == LEVEL_ORDER
      raise "Department title mismatch" unless DEPARTMENT_COUNTS.keys.sort == TITLES.keys.sort

      TITLES.each do |department, titles|
        raise "#{department} needs #{LEVEL_ORDER.length} titles" unless titles.length == LEVEL_ORDER.length
      end
      LEVEL_ORDER.each { |level| LEVELS.fetch(level) }
    end

    def self.country(code)
      COUNTRIES.find { |country| country[:code] == code }
    end

    def self.title_for(department, level)
      TITLES.fetch(department).fetch(LEVEL_ORDER.index(level))
    end

    def self.band_for(country_code, level)
      country = country(country_code)
      mid_usd = LEVELS.fetch(level)[:usd_mid].to_d * country[:factor].to_d
      mid_local = (mid_usd / country[:fx_to_usd].to_d).round(2)
      {
        min: (mid_local * BigDecimal("0.80")).round(2),
        mid: mid_local,
        max: (mid_local * BigDecimal("1.25")).round(2),
        currency: country[:currency]
      }
    end

    def self.level_order_sql(direction)
      cases = LEVEL_ORDER.each_with_index.map do |level, index|
        "WHEN #{ActiveRecord::Base.connection.quote(level)} THEN #{index}"
      end.join(" ")
      "CASE employees.job_level #{cases} ELSE #{LEVEL_ORDER.length} END #{direction}"
    end

    def self.filters
      {
        countries: COUNTRIES.map { |country| { code: country[:code], name: country[:name] } },
        departments: DEPARTMENT_COUNTS.keys,
        levels: LEVEL_ORDER,
        statuses: [
          { value: "current", label: "Active and on leave" },
          { value: "active", label: "Active" },
          { value: "on_leave", label: "On leave" },
          { value: "terminated", label: "Terminated" },
          { value: "all", label: "Everyone" }
        ],
        employment_types: [
          { value: "full_time", label: "Full time" },
          { value: "part_time", label: "Part time" },
          { value: "contractor", label: "Contractor" }
        ],
        genders: [
          { value: "female", label: "Women" },
          { value: "male", label: "Men" },
          { value: "non_binary", label: "Non-binary" },
          { value: "undisclosed", label: "Undisclosed" }
        ],
        bands: [
          { value: "outside", label: "Outside band" },
          { value: "below", label: "Below band" },
          { value: "above", label: "Above band" },
          { value: "in_band", label: "In band" }
        ]
      }
    end
  end
end
