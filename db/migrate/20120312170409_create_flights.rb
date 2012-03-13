class CreateFlights < ActiveRecord::Migration
  def up
    create_table :flights do |t|
      t.decimal :price, precision: 10, scale: 2, null: false
      t.datetime :departure, null: false
      t.datetime :arrival, null: false
      t.string :from, limit: 3, null: false
      t.string :to, limit: 3, null: false
    end
    add_index :flights, [:from, :to]
    add_index :flights, :departure
    add_index :flights, :price
    execute "CREATE INDEX travel_time ON flights (EXTRACT(EPOCH FROM (arrival - departure)))"
  end

  def down
    drop_table :flights
  end
end
