class CreatePayline < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :salary_bands do |t|
      t.string :country_code, null: false
      t.string :country_name, null: false
      t.string :job_level, null: false
      t.string :currency, null: false
      t.decimal :min_salary, precision: 14, scale: 2, null: false
      t.decimal :mid_salary, precision: 14, scale: 2, null: false
      t.decimal :max_salary, precision: 14, scale: 2, null: false
      t.timestamps
    end
    add_index :salary_bands, [ :country_code, :job_level ], unique: true

    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :country_code, null: false
      t.string :country_name, null: false
      t.string :city, null: false
      t.string :department, null: false
      t.string :job_title, null: false
      t.string :job_level, null: false
      t.string :employment_type, null: false
      t.string :gender, null: false
      t.date :hire_date, null: false
      t.string :status, null: false
      t.string :currency, null: false
      t.decimal :base_salary_annual, precision: 14, scale: 2, null: false
      t.decimal :bonus_target_percent, precision: 5, scale: 2, null: false
      t.decimal :annual_allowance, precision: 14, scale: 2, null: false
      t.decimal :fx_rate_to_usd, precision: 12, scale: 6, null: false
      t.decimal :base_salary_usd, precision: 14, scale: 2, null: false
      t.decimal :total_cash_usd, precision: 14, scale: 2, null: false
      t.date :comp_effective_on, null: false
      t.timestamps
    end
    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, :country_code
    add_index :employees, :department
    add_index :employees, :job_level
    add_index :employees, :status
    add_index :employees, :employment_type
    add_index :employees, [ :country_code, :job_level ]
    add_index :employees, :base_salary_usd

    create_table :compensation_changes do |t|
      t.references :employee, null: false, foreign_key: true
      t.decimal :base_salary_before, precision: 14, scale: 2, null: false
      t.decimal :base_salary_after, precision: 14, scale: 2, null: false
      t.decimal :bonus_before, precision: 5, scale: 2, null: false
      t.decimal :bonus_after, precision: 5, scale: 2, null: false
      t.decimal :allowance_before, precision: 14, scale: 2, null: false
      t.decimal :allowance_after, precision: 14, scale: 2, null: false
      t.string :currency, null: false
      t.string :reason, null: false
      t.date :effective_on, null: false
      t.timestamps
    end
  end
end
