namespace :demo do
  desc 'Generate demo data'
  task generate: :environment do
    FactoryGirl.create_list(:flight, 100000)
  end
end
