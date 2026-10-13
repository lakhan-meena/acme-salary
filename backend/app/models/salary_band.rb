class SalaryBand < ApplicationRecord
  validates :country_code, :country_name, :job_level, :currency, presence: true
  validates :job_level, uniqueness: { scope: :country_code }
  validates :min_salary, :mid_salary, :max_salary, numericality: { greater_than: 0 }
end
