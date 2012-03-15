FactoryGirl.define do
  sequence(:iata) { 3.times.map{rand(65..67).chr}.join } # IATA codes are generated from AAA to CCC to reduce amount of airports.

  factory :flight do
    from      { FactoryGirl.generate :iata }
    to        { FactoryGirl.generate :iata }
    departure { Date.today.to_time(:utc) + rand(300000).minutes }
    arrival   { departure + rand(60..1200).minutes }
    price     { rand(10..1000) }
  end
end