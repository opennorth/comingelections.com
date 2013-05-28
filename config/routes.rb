ComingElections::Application.routes.draw do
  get "election_schedule/index"

  devise_for :users
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  resources :elections, only: :index
  root to: 'elections#index'

  match '/scheduled',        to: 'election_schedule#index'

end
