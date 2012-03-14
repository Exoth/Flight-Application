require 'spec_helper'

describe Flight do

  describe 'self.select_self_join' do
    it 'should return self joined elements in pairs with right attributes' do
      flight = FactoryGirl.create(:flight)
      joined_flight = FactoryGirl.create(:flight)
      Flight.select_self_join(Flight.select('*').where(id: flight.id).joins("JOIN flights AS joined_flights ON joined_flights.id = #{joined_flight.id}"))[0].
        map(&:attributes).should == [flight, joined_flight].map(&:attributes)
    end
  end

  describe 'self.search(attrs)' do
    it 'should find a single flight in array given a set of attributes' do
      flight = FactoryGirl.create(:flight)
      Flight.search(flight.attributes.symbolize_keys.slice( *Flight::SEARCH_ATTRS )).should == [[flight]]
    end

    it 'it should find a pair of flights in array given a set of attributes with stopover point' do
      flight = FactoryGirl.create(:flight, to: "ABC", departure: '01-01-2012', arrival: '02-01-2012')
      departure = flight.arrival + Flight::STOPOVER_TIME.min
      second_flight = FactoryGirl.create(:flight, from: "ABC", departure: departure, arrival: departure + 1.day)
      Flight.search(from: flight.from, to: second_flight.to, stopover: flight.to, travel_time: (second_flight.arrival - flight.departure).to_i,
                    departure: flight.departure, price: flight.price + second_flight.price).should == [[flight, second_flight]]
    end
  end

end
