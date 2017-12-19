Rails.application.routes.draw do
  # resources :sessions, only: [:create]
  post 'login', to: 'sessions#create'
  resources :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope path: '/users/:user_id' do
    resources :microposts, only: [:index]
  end
end
