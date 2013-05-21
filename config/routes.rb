ComingElections::Application.routes.draw do
  resources :elections
  root :to => "elections#index"
end
