Rails.application.routes.draw do
  resources :resumes, only: [:index, :new, :create, :destroy]
  root 'resumes#index'

  # post 'upload', to: 'resumes#upload'
  resources :resumes do
    post :upload, on: :collection
  end
end
