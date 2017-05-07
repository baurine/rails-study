Rails.application.routes.draw do
  get 'admin/index'

  get 'sessions/new'
  get 'sessions/create'
  get 'sessions/destroy'

  resources :orders
  resources :line_items
  resources :carts

  resources :products do
    get :who_bought, on: :member
  end

  resources :users

  root 'store#index', as: 'store_index'
end
