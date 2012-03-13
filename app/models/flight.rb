class Flight < ActiveRecord::Base
  validates_length_of :from, is: 3 # IATA code
  validates_length_of :to, is: 3   # IATA code
  validates_presence_of :departure, :arrival
  validates_numericality_of :price, greater_than: 0

  scope :departure_day, proc {|departure| where(flights: {departure: departure..(departure + 1.day - 1)}) }

  def as_json(options={})
    serializable_hash.select{|k,v| %w(departure arrival from to price).include?(k)}
  end

  def self.search(attrs, options = {})
    if attrs.is_a?(Hash)
      attrs = attrs.with_indifferent_access
      if %w(from to departure) - attrs.keys == []
        begin # Checking that arguments are valid.
          travel_time = attrs[:travel_time] && Integer(attrs[:travel_time])
          attrs[:price] && Float(attrs[:price])
          departure = Date.parse(attrs[:departure]).to_time(:utc) # Assuming that all flight datetimes are stored in UTC
        rescue
          return nil
        end
        flight_groups = if attrs[:stopover]   # Stopover is between one hour and one day.
          select_self_join( joins('JOIN flights AS joined_flights ON EXTRACT(EPOCH FROM (joined_flights.departure - flights.arrival)) BETWEEN 3600 AND 86400').
            where(flights: {from: attrs[:from], to: attrs[:stopover]}, joined_flights: {from: attrs[:stopover], to: attrs[:to]}).
            select('*').departure_day(departure).
            where(attrs[:price] && ['flights.price + joined_flights.price <= ?', attrs[:price]]).
            where(travel_time && ['EXTRACT(EPOCH FROM (joined_flights.arrival - flights.departure)) <= ?', travel_time]) )
        else
          departure_day(departure).where(from: attrs[:from], to: attrs[:to]).
            where(attrs[:price] && ['price <= ?', attrs[:price]]).
            where(travel_time && ['EXTRACT(EPOCH FROM (arrival - departure)) <= ?', travel_time]). # Travel time in seconds
            map{|flight| [flight]}
        end
        options[:extract_prices] ? flight_groups.map{|flight_group| {price: flight_group.map(&:price).sum, flights: flight_group}} : flight_groups
      end
    end
  end

  # Selects self joined flights in pairs.
  def self.select_self_join(request)
    connection.select_rows(request.to_sql).map{|row| row.each_slice(row.size / 2).map{|flight| instantiate(Hash[columns.map(&:name).zip(flight)])} }
  end

end