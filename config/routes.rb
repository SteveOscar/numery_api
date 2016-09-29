Rails.application.routes.draw do
  resources :users

  get '/scores/:device', to: 'scores#high_scores'
  post '/scores/new/:user_id/:device/:score', to: 'scores#create'
end
