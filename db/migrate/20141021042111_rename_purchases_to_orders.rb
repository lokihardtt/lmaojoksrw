class RenamePurchasesToOrders < ActiveRecord::Migration
  def change
    rename_table :purchases, :orders
  end
end
