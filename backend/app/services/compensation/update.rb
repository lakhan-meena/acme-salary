module Compensation
  class Update
    Result = Struct.new(:employee, :errors, keyword_init: true) do
      def ok?
        errors.blank?
      end
    end

    def initialize(employee, attributes, reason:)
      @employee = employee
      @attributes = attributes
      @reason = reason.to_s.strip
    end

    def call
      next_pay = {
        base_salary_annual: @attributes[:base_salary_annual],
        bonus_target_percent: @attributes[:bonus_target_percent],
        annual_allowance: @attributes[:annual_allowance]
      }

      if next_pay.values.any?(&:nil?)
        return Result.new(employee: @employee, errors: [ "Base, bonus, and allowance are required." ])
      end

      if @reason.length > 500
        return Result.new(employee: @employee, errors: [ "Reason must be 500 characters or fewer." ])
      end

      unchanged = next_pay.all? { |key, value| @employee.public_send(key).to_d == value.to_d }
      if unchanged
        return Result.new(employee: @employee, errors: [ "Change base, bonus, or allowance before saving." ])
      end

      if @reason.blank?
        return Result.new(employee: @employee, errors: [ "A reason is required when pay changes." ])
      end

      before = {
        base: @employee.base_salary_annual,
        bonus: @employee.bonus_target_percent,
        allowance: @employee.annual_allowance
      }

      @employee.assign_attributes(next_pay)
      @employee.comp_effective_on = Date.current
      unless @employee.valid?
        return Result.new(employee: @employee, errors: @employee.errors.full_messages)
      end

      Employee.transaction do
        @employee.save!
        @employee.compensation_changes.create!(
          base_salary_before: before[:base],
          base_salary_after: @employee.base_salary_annual,
          bonus_before: before[:bonus],
          bonus_after: @employee.bonus_target_percent,
          allowance_before: before[:allowance],
          allowance_after: @employee.annual_allowance,
          currency: @employee.currency,
          reason: @reason,
          effective_on: @employee.comp_effective_on
        )
      end

      Result.new(employee: @employee, errors: [])
    end
  end
end
