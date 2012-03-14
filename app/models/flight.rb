class Flight < ActiveRecord::Base
  validates_length_of :from, is: 3 # IATA code
  validates_length_of :to, is: 3   # IATA code
  validates_presence_of :departure, :arrival
  validates_numericality_of :price, greater_than: 0

  SEARCH_ATTRS = [:from, :to, :travel_time, :departure, :price, :stopover]

  STOPOVER_TIME = 3600..86400

  scope :joins_for_stopover, joins(
   "JOIN flights AS joined_flights
    ON EXTRACT(EPOCH FROM (joined_flights.departure - flights.arrival))
    BETWEEN #{STOPOVER_TIME.min} AND #{STOPOVER_TIME.max}" # Stopover is between one hour and one day.
  )
  scope :with_departure_day, -> departure {
    where departure: departure..(departure + 1.day - 1)
  }
  scope :with_price, -> price, joined = nil {
    sql = joined ? "flights.price + joined_flights.price <= ?" : "price <= ?"
    where(sql, price) if price
  }
  scope :with_travel_time, -> travel_time, joined = nil {
    sql = joined ? "EXTRACT(EPOCH FROM (joined_flights.arrival - flights.departure)) <= ?" :
                   "EXTRACT(EPOCH FROM (arrival - departure)) <= ?"
    where(sql, travel_time) if travel_time
  }

  def as_json(options = {})
    super(options.merge(only: %w(departure arrival from to)))
  end

  def self.search_variants(attrs)
    search(attrs).map do |flight_group|
      {price: flight_group.map(&:price).sum, flights: flight_group}
    end
  end

  def self.search(attrs)
    raise ArgumentError unless attrs.is_a?(Hash) && attrs.values_at(:from, :to, :departure).all?
    attrs[:travel_time] &&= Integer(attrs[:travel_time]) # Travel time in seconds
    attrs[:price] &&= BigDecimal(attrs[:price])
    # Assuming that all flight datetimes are stored in UTC
    attrs[:departure] = Date.parse(attrs[:departure]).to_time(:utc) unless attrs[:departure].is_a?(Time) # YY-MM-DD
    flight_groups = with_departure_day(attrs[:departure]).with_price(attrs[:price], attrs[:stopover]).with_travel_time(attrs[:travel_time], attrs[:stopover])
    if attrs[:stopover]
      select_self_join( flight_groups.joins_for_stopover.select('*').
        where(flights:        {from: attrs[:from],     to: attrs[:stopover]},
              joined_flights: {from: attrs[:stopover], to: attrs[:to]}))
    else
      flight_groups.where(from: attrs[:from], to: attrs[:to]).map{|flight| [flight]}
    end
  end

  # Selects self joined flights in pairs.
  def self.select_self_join(request)
    connection.select_rows(request.to_sql).map do |row|
      row.each_slice(row.size / 2).map do |flight_attrs|
        instantiate( Hash[column_names.zip(flight_attrs)] )
      end
    end
  end

end