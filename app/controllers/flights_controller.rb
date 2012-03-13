class FlightsController < ApplicationController
  respond_to :json

  def index
    flights = Flight.search(params.select{|k,v| %w(from to travel_time departure price stopover).include?(k) }, extract_prices: true)
    flights ? respond_with(flights) : respond_with("Invalid arguments.", status: 400)
  end
end