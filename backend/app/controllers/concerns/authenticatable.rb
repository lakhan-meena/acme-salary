module Authenticatable
  extend ActiveSupport::Concern

  private

  def authenticate!
    token = request.authorization.to_s.delete_prefix("Bearer ").strip
    @current_user = User.find_by_token_for(:api, token) if token.present?
    render json: { error: "Sign in required" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
