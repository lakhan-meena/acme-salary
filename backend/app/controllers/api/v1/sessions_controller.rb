module Api
  module V1
    class SessionsController < ApplicationController
      skip_before_action :authenticate!, only: :create

      def create
        user = User.find_by(email: params[:email].to_s.downcase.strip)
        if user&.authenticate(params[:password])
          render json: { token: user.generate_token_for(:api), user: user_json(user) }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def show
        render json: { user: user_json(current_user) }
      end

      private

      def user_json(user)
        { name: user.name, email: user.email }
      end
    end
  end
end
