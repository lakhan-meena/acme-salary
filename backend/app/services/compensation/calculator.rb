module Compensation
  module Calculator
    module_function

    def usd_amounts(base:, bonus_percent:, allowance:, fx:)
      base = base.to_d
      allowance = allowance.to_d
      fx = fx.to_d
      local_total = base + (base * bonus_percent.to_d / 100) + allowance
      {
        base_salary_usd: (base * fx).round(2),
        total_cash_usd: (local_total * fx).round(2)
      }
    end
  end
end
