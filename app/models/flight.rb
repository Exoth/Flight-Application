class Flight < ActiveRecord::Base
  validates_length_of :from, is: 3 # IATA code
  validates_length_of :to, is: 3   # IATA code
  validates_presence_of :departure, :arrival
  validates_numericality_of :price, greater_than: 0

  def as_json(options={})
    serializable_hash.select{|k,v| %w(departure arrival from to price).include?(k)}
  end

  def self.search(attrs, options = {})
    if attrs.is_a?(Hash)
      attrs = attrs.with_indifferent_access
      if %w(from to departure) - attrs.keys == []
        begin
          travel_time = attrs[:travel_time] && Integer(attrs[:travel_time])
          attrs[:price] && Float(attrs[:price])
          departure = Date.parse(attrs[:departure]).to_time(:utc) # Assuming that all flight datetimes are stored in UTC
        rescue
          return nil
        end
        flight_groups = where(departure: departure..(departure + 1.day - 1), from: attrs[:from], to: attrs[:to]).
          where(attrs[:price] && ['price <= ?', attrs[:price]]).
          where(travel_time && ['EXTRACT(EPOCH FROM (arrival - departure)) <= ?', travel_time]). # Travel time in seconds
          map{|flight| [flight]}
        options[:extract_prices] ? flight_groups.map{|flight_group| {price: flight_group.map(&:price).sum, flights: flight_group}} : flight_groups
      end
    end
  end
end