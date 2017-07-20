class RemoveShipToFromItem < ActiveRecord::Migration
  def change
    remove_column :items, :ship_to
  end
end
