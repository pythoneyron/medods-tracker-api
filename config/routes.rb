Rails.application.routes.draw do
  devise_for :users, skip: %i[sessions registrations]

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post "users", to: "users/registrations#create", defaults: { format: :json }
        post "users/sign_in", to: "users/sessions#create", defaults: { format: :json }
        delete "users/sign_out", to: "users/sessions#destroy", defaults: { format: :json }
      end

      resources :tasks do
        resources :task_tags, only: %i[create destroy], path: "tags", param: :tag_id
        resources :task_occurrences, only: %i[update], path: "occurrences", param: :date
      end

      resources :tags
    end
  end
end
