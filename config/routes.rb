FlightApp::Application.routes.draw do
  resources :flights, only: :index
end
