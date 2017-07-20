class RemoveShipFromInItem < ActiveRecord::Migration
  def change
    remove_column :items, :ship_from
  end
end
