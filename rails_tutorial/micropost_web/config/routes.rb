Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # root 'application#hello'
  root 'static_pages#home'
  # get '/help',  to:   'static_pages#help', as: 'helf'
  get '/help',    to: 'static_pages#help'
  get '/about',   to: 'static_pages#about'
  get '/contact', to: 'static_pages#contact'

  # user
  get '/signup',  to: 'users#new'
  # resources :users, except: :new
  resources :users
end
