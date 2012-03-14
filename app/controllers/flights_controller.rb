class FlightsController < ApplicationController
  respond_to :json

  rescue_from ArgumentError do |exception|
    respond_with({error: exception.message}, status: 400)
  end

  def index
    respond_with( Flight.search_variants( params.slice( *Flight::SEARCH_ATTRS ) ) )
  end
end