require "test_helper"

class PaylineApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(name: "HR Manager", email: "hr.manager@acme.test", password: "acme-hr-demo")
    @band = SalaryBand.create!(
      country_code: "US",
      country_name: "United States",
      job_level: "IC3",
      currency: "USD",
      min_salary: 80_000,
      mid_salary: 100_000,
      max_salary: 125_000
    )
    @employee = Employee.create!(
      employee_code: "ACME-00001",
      first_name: "Ada",
      last_name: "Okoye",
      email: "ada.okoye@acme.test",
      country_code: "US",
      country_name: "United States",
      city: "Austin",
      department: "Engineering",
      job_title: "Senior Software Engineer",
      job_level: "IC3",
      employment_type: "full_time",
      gender: "female",
      hire_date: Date.new(2020, 3, 1),
      status: "active",
      currency: "USD",
      base_salary_annual: 98_000,
      bonus_target_percent: 10,
      annual_allowance: 6_000,
      fx_rate_to_usd: 1,
      comp_effective_on: Date.new(2025, 4, 1)
    )
  end

  test "sign in rejects a bad password and accepts the HR manager" do
    post "/api/v1/session", params: { email: @user.email, password: "wrong-password" }, as: :json
    assert_response :unauthorized

    post "/api/v1/session", params: { email: @user.email, password: "acme-hr-demo" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["token"].present?
    assert_equal "HR Manager", body.dig("user", "name")
  end

  test "employee list requires a session and returns the person" do
    get "/api/v1/employees"
    assert_response :unauthorized

    get "/api/v1/employees", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.dig("meta", "total")
    assert_equal "ACME-00001", body.dig("employees", 0, "employee_code")
    assert_equal "in_band", body.dig("employees", 0, "band_position")
  end

  test "updating pay stores a reason and refreshes the USD amount" do
    patch "/api/v1/employees/#{@employee.id}",
      params: { employee: { base_salary_annual: 110_000, bonus_target_percent: 10, annual_allowance: 6_000 } },
      headers: auth_headers,
      as: :json
    assert_response :unprocessable_entity

    patch "/api/v1/employees/#{@employee.id}",
      params: {
        employee: {
          base_salary_annual: 110_000,
          bonus_target_percent: 10,
          annual_allowance: 6_000,
          change_reason: "Market adjustment"
        }
      },
      headers: auth_headers,
      as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 110_000, body.dig("employee", "base_salary_annual")
    assert_equal 127_000, body.dig("employee", "total_cash_usd")
    assert_equal "Market adjustment", body.dig("employee", "changes", 0, "reason")
    assert_equal 1, @employee.compensation_changes.count
  end

  test "insights answers from the current workforce" do
    get "/api/v1/insights", headers: auth_headers
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.dig("workforce", "current")
    assert body["questions"].any? { |question| question["id"] == "pay_equity" }
    assert body["headline"].present?
  end

  private

  def auth_headers
    post "/api/v1/session", params: { email: @user.email, password: "acme-hr-demo" }, as: :json
    token = JSON.parse(response.body).fetch("token")
    { "Authorization" => "Bearer #{token}" }
  end
end
