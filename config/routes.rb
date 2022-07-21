Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  post "/download", to: "api#download", as: "download"
  options "/download", to: "api#post_preflight", as: "download_preflight"

  # Defines the root path route ("/")
  # root "articles#index"
end
