module Api
  module V1
    class SalaryBandsController < ApplicationController
      def index
        country = Compensation::Catalog.country(params[:country].presence || "US") || Compensation::Catalog.country("US")
        bands = SalaryBand.where(country_code: country[:code]).index_by(&:job_level)
        full_time = Employee.current_workforce.where(employment_type: "full_time", country_code: country[:code])
        grouped = full_time.pluck(:job_level, :base_salary_annual).group_by(&:first)

        render json: {
          countries: Compensation::Catalog::COUNTRIES.map { |row| { code: row[:code], name: row[:name], currency: row[:currency] } },
          country: { code: country[:code], name: country[:name], currency: country[:currency] },
          bands: Compensation::Catalog::LEVEL_ORDER.map { |level| band_row(level, bands[level], grouped[level] || []) }
        }
      end

      private

      def band_row(level, band, people)
        bases = people.map { |_, base| base.to_f }
        outside = if band
          bases.count { |base| base < band.min_salary.to_f || base > band.max_salary.to_f }
        else
          0
        end

        {
          job_level: level,
          title_hint: level.start_with?("M") ? "Manager" : "Individual contributor",
          currency: band&.currency || country_currency,
          min: band ? band.min_salary.to_f : nil,
          mid: band ? band.mid_salary.to_f : nil,
          max: band ? band.max_salary.to_f : nil,
          headcount: bases.size,
          median_base: bases.empty? ? nil : median(bases),
          outside_count: outside
        }
      end

      def country_currency
        Compensation::Catalog.country(params[:country].presence || "US")&.dig(:currency)
      end

      def median(values)
        sorted = values.sort
        mid = sorted.length / 2
        sorted.length.odd? ? sorted[mid].round(2) : ((sorted[mid - 1] + sorted[mid]) / 2.0).round(2)
      end
    end
  end
end
