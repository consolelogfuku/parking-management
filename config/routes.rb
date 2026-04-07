Rails.application.routes.draw do
  devise_for :admin_users, path: "admin", path_names: { sign_in: "login", sign_out: "logout" }, controllers: {
    sessions: "admin/sessions"
  }
  devise_for :users, path: "", path_names: { sign_in: "login", sign_out: "logout" }, controllers: {
    sessions: "users/sessions"
  }

  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :parkings
    resources :admin_users, except: %i[show]
  end

  namespace :manage do
    resources :parkings, except: %i[show] do
      member do
        get :qr
        get :qr_pdf
      end
    end
  end

  get "public/:id", to: "public/parkings#show", as: :public_parking

  get "up" => "rails/health#show", as: :rails_health_check

  root "public/top#index"
end
