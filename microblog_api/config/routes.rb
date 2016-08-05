Rails.application.routes.draw do
  # resources :sessions, only: [:create]
  post 'login', to: 'sessions#create'
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
