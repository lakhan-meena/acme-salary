module Api
  module V1
    class EmployeesController < ApplicationController
      SORTS = {
        "name" => "employees.last_name %{dir}, employees.first_name %{dir}",
        "country" => "employees.country_name %{dir}",
        "department" => "employees.department %{dir}",
        "base_usd" => "employees.base_salary_usd %{dir}",
        "total_usd" => "employees.total_cash_usd %{dir}",
        "hire_date" => "employees.hire_date %{dir}",
        "code" => "employees.employee_code %{dir}"
      }.freeze

      def index
        scope = filtered_employees
        total = scope.count
        page = [ params[:page].to_i, 1 ].max
        per_page = params[:per_page].to_i
        per_page = 25 if per_page <= 0
        per_page = 100 if per_page > 100
        rows = ordered(scope).offset((page - 1) * per_page).limit(per_page).to_a
        bands = bands_for(rows)

        render json: {
          employees: rows.map { |employee| employee.as_api_json(band: bands[[ employee.country_code, employee.job_level ]]) },
          meta: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: (total.to_f / per_page).ceil
          },
          filters: Compensation::Catalog.filters
        }
      end

      def filters
        render json: Compensation::Catalog.filters
      end

      def show
        employee = Employee.find(params[:id])
        render json: { employee: detail_json(employee) }
      end

      def update
        employee = Employee.find(params[:id])
        result = Compensation::Update.new(
          employee,
          employee_params,
          reason: params.dig(:employee, :change_reason)
        ).call

        if result.ok?
          render json: { employee: detail_json(result.employee) }
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def employee_params
        params.require(:employee).permit(:base_salary_annual, :bonus_target_percent, :annual_allowance)
      end

      def detail_json(employee)
        changes = employee.compensation_changes.order(effective_on: :desc, id: :desc)
        employee.as_api_json(changes: changes)
      end

      def filtered_employees
        scope = Employee.all
        scope = scope.where(country_code: params[:country]) if params[:country].present?
        scope = scope.where(department: params[:department]) if params[:department].present?
        scope = scope.where(job_level: params[:level]) if params[:level].present?
        scope = scope.where(employment_type: params[:employment_type]) if params[:employment_type].present?
        scope = scope.where(gender: params[:gender]) if params[:gender].present?
        scope = apply_status(scope)
        scope = apply_query(scope)
        apply_band(scope, params[:band])
      end

      def apply_status(scope)
        case params[:status].presence || "current"
        when "all" then scope
        when "current" then scope.where(status: Employee::CURRENT_STATUSES)
        when "active", "on_leave", "terminated" then scope.where(status: params[:status])
        else scope.where(status: Employee::CURRENT_STATUSES)
        end
      end

      def apply_query(scope)
        return scope if params[:q].blank?

        like = "%#{Employee.sanitize_sql_like(params[:q].strip)}%"
        scope.where(
          "employees.first_name LIKE :q OR employees.last_name LIKE :q OR employees.email LIKE :q OR employees.employee_code LIKE :q OR employees.job_title LIKE :q OR (employees.first_name || ' ' || employees.last_name) LIKE :q",
          q: like
        )
      end

      def apply_band(scope, band)
        return scope if band.blank?

        scope = scope.where(employment_type: "full_time")
        joined = scope.joins(<<~SQL.squish)
          INNER JOIN salary_bands
            ON salary_bands.country_code = employees.country_code
           AND salary_bands.job_level = employees.job_level
        SQL

        case band
        when "below"
          joined.where("employees.base_salary_annual < salary_bands.min_salary")
        when "above"
          joined.where("employees.base_salary_annual > salary_bands.max_salary")
        when "outside"
          joined.where("employees.base_salary_annual < salary_bands.min_salary OR employees.base_salary_annual > salary_bands.max_salary")
        when "in_band"
          joined.where("employees.base_salary_annual >= salary_bands.min_salary AND employees.base_salary_annual <= salary_bands.max_salary")
        else
          scope
        end
      end

      def ordered(scope)
        direction = params[:direction] == "desc" ? "DESC" : "ASC"
        if params[:sort] == "level"
          scope.order(Arel.sql(Compensation::Catalog.level_order_sql(direction)))
        else
          template = SORTS.fetch(params[:sort], SORTS["code"])
          scope.order(Arel.sql(format(template, dir: direction)))
        end
      end

      def bands_for(employees)
        return {} if employees.empty?

        SalaryBand.where(country_code: employees.map(&:country_code).uniq).index_by do |band|
          [ band.country_code, band.job_level ]
        end
      end
    end
  end
end
