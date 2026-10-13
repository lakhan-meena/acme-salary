Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "session", to: "sessions#create"
      get "session", to: "sessions#show"
      get "insights", to: "insights#show"
      resources :salary_bands, only: [ :index ]
      resources :employees, only: [ :index, :show, :update ] do
        collection do
          get :filters
        end
      end
    end
  end
end
