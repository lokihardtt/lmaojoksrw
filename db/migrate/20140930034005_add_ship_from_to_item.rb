class AddShipFromToItem < ActiveRecord::Migration
  def change
    add_column :items, :ship_from, :integer
  end
end
