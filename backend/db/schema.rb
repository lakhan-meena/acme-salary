# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_13_103000) do
  create_table "compensation_changes", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.decimal "base_salary_before", precision: 14, scale: 2, null: false
    t.decimal "base_salary_after", precision: 14, scale: 2, null: false
    t.decimal "bonus_before", precision: 5, scale: 2, null: false
    t.decimal "bonus_after", precision: 5, scale: 2, null: false
    t.decimal "allowance_before", precision: 14, scale: 2, null: false
    t.decimal "allowance_after", precision: 14, scale: 2, null: false
    t.string "currency", null: false
    t.string "reason", null: false
    t.date "effective_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_compensation_changes_on_employee_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "country_code", null: false
    t.string "country_name", null: false
    t.string "city", null: false
    t.string "department", null: false
    t.string "job_title", null: false
    t.string "job_level", null: false
    t.string "employment_type", null: false
    t.string "gender", null: false
    t.date "hire_date", null: false
    t.string "status", null: false
    t.string "currency", null: false
    t.decimal "base_salary_annual", precision: 14, scale: 2, null: false
    t.decimal "bonus_target_percent", precision: 5, scale: 2, null: false
    t.decimal "annual_allowance", precision: 14, scale: 2, null: false
    t.decimal "fx_rate_to_usd", precision: 12, scale: 6, null: false
    t.decimal "base_salary_usd", precision: 14, scale: 2, null: false
    t.decimal "total_cash_usd", precision: 14, scale: 2, null: false
    t.date "comp_effective_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_salary_usd"], name: "index_employees_on_base_salary_usd"
    t.index ["country_code", "job_level"], name: "index_employees_on_country_code_and_job_level"
    t.index ["country_code"], name: "index_employees_on_country_code"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["job_level"], name: "index_employees_on_job_level"
    t.index ["status"], name: "index_employees_on_status"
  end

  create_table "salary_bands", force: :cascade do |t|
    t.string "country_code", null: false
    t.string "country_name", null: false
    t.string "job_level", null: false
    t.string "currency", null: false
    t.decimal "min_salary", precision: 14, scale: 2, null: false
    t.decimal "mid_salary", precision: 14, scale: 2, null: false
    t.decimal "max_salary", precision: 14, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "job_level"], name: "index_salary_bands_on_country_code_and_job_level", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "compensation_changes", "employees"
end
