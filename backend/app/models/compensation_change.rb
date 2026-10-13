class CompensationChange < ApplicationRecord
  belongs_to :employee

  validates :reason, :currency, :effective_on, presence: true

  def as_api_json
    {
      id: id,
      base_salary_before: num(base_salary_before),
      base_salary_after: num(base_salary_after),
      bonus_before: num(bonus_before),
      bonus_after: num(bonus_after),
      allowance_before: num(allowance_before),
      allowance_after: num(allowance_after),
      currency: currency,
      reason: reason,
      effective_on: effective_on
    }
  end

  private

  def num(value)
    value.to_d.round(2).to_f
  end
end
