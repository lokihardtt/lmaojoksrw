class AddItemNameToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :item_name, :string
  end
end
