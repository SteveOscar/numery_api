Rails.application.routes.draw do
  resources :users

  get "/scores/:device", to: "scores#high_scores"
  post "/scores/new/:device/", to: "scores#create"
end
