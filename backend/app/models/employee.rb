class Employee < ApplicationRecord
  CURRENT_STATUSES = %w[active on_leave].freeze

  has_many :compensation_changes, dependent: :destroy

  before_validation :fill_usd_amounts

  validates :employee_code, :first_name, :last_name, :email, :country_code, :country_name,
    :city, :department, :job_title, :job_level, :employment_type, :gender, :hire_date,
    :status, :currency, :comp_effective_on, presence: true
  validates :employee_code, :email, uniqueness: true
  validates :base_salary_annual, numericality: { greater_than: 0 }
  validates :bonus_target_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :annual_allowance, numericality: { greater_than_or_equal_to: 0 }
  validates :fx_rate_to_usd, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[active on_leave terminated] }
  validates :employment_type, inclusion: { in: %w[full_time part_time contractor] }
  validates :gender, inclusion: { in: %w[female male non_binary undisclosed] }
  validates :job_level, inclusion: { in: Compensation::Catalog::LEVEL_ORDER }

  scope :current_workforce, -> { where(status: CURRENT_STATUSES) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def as_api_json(band: :load, changes: nil)
    resolved_band = band == :load ? salary_band : band
    payload = {
      id: id,
      employee_code: employee_code,
      full_name: full_name,
      first_name: first_name,
      last_name: last_name,
      email: email,
      country_code: country_code,
      country_name: country_name,
      city: city,
      department: department,
      job_title: job_title,
      job_level: job_level,
      employment_type: employment_type,
      hire_date: hire_date,
      status: status,
      currency: currency,
      base_salary_annual: num(base_salary_annual),
      bonus_target_percent: num(bonus_target_percent),
      annual_allowance: num(annual_allowance),
      fx_rate_to_usd: fx_rate_to_usd.to_f,
      base_salary_usd: num(base_salary_usd),
      total_cash_usd: num(total_cash_usd),
      comp_effective_on: comp_effective_on,
      band_position: band_position(resolved_band),
      compa_ratio: compa_ratio_for(resolved_band),
      band: band_json(resolved_band)
    }
    payload[:changes] = changes.map(&:as_api_json) if changes
    payload
  end

  def salary_band
    SalaryBand.find_by(country_code: country_code, job_level: job_level)
  end

  private

  def fill_usd_amounts
    return if base_salary_annual.blank? || bonus_target_percent.blank? || annual_allowance.blank? || fx_rate_to_usd.blank?

    amounts = Compensation::Calculator.usd_amounts(
      base: base_salary_annual,
      bonus_percent: bonus_target_percent,
      allowance: annual_allowance,
      fx: fx_rate_to_usd
    )
    self.base_salary_usd = amounts[:base_salary_usd]
    self.total_cash_usd = amounts[:total_cash_usd]
  end

  def band_position(band)
    return "not_applicable" unless employment_type == "full_time" && band

    if base_salary_annual < band.min_salary
      "below"
    elsif base_salary_annual > band.max_salary
      "above"
    else
      "in_band"
    end
  end

  def compa_ratio_for(band)
    return nil unless employment_type == "full_time" && band&.mid_salary&.positive?

    (base_salary_annual / band.mid_salary).round(3).to_f
  end

  def band_json(band)
    return nil unless band

    {
      min: num(band.min_salary),
      mid: num(band.mid_salary),
      max: num(band.max_salary),
      currency: band.currency
    }
  end

  def num(value)
    value.to_d.round(2).to_f
  end
end
