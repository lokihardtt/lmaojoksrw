class AddShippingIdToShoppingCartItem < ActiveRecord::Migration
  def change
    add_column :shopping_cart_items, :shipping_id, :integer
  end
end
