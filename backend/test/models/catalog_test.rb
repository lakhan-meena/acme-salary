require "test_helper"

class CatalogTest < ActiveSupport::TestCase
  test "reference counts cover 10,000 employees" do
    assert_nothing_raised { Compensation::Catalog.check! }
  end

  test "usd total cash includes base, target bonus, and allowance" do
    amounts = Compensation::Calculator.usd_amounts(base: 100_000, bonus_percent: 10, allowance: 5_000, fx: 1)
    assert_equal BigDecimal("100000.00"), amounts[:base_salary_usd]
    assert_equal BigDecimal("115000.00"), amounts[:total_cash_usd]
  end
end
