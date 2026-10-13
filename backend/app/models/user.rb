class User < ApplicationRecord
  has_secure_password
  generates_token_for :api, expires_in: 7.days

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
end
