Rails.application.routes.draw do
  root 'home#index'

  get '/start', to: 'quiz_sessions#new'
  get '/join', to: 'quiz_participants#new'

  resources :quiz_sessions, only: [:new, :create, :show] do
    member do
      get :host_control
      post :start
      post :advance_question
      post :reveal_answer
      post :finish
    end
  end

  resources :quiz_participants, only: [:new, :create, :show] do
    member do
      post :submit_answer
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
