class AddShippingIdToPurchase < ActiveRecord::Migration
  def change
    add_column :purchases, :shipping_id, :integer
  end
end
