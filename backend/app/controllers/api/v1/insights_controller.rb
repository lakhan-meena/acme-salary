module Api
  module V1
    class InsightsController < ApplicationController
      def show
        render json: Insights::Report.new.to_h
      end
    end
  end
end
