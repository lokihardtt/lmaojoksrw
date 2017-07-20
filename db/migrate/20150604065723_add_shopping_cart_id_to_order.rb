class AddShoppingCartIdToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :shopping_cart_id, :integer
  end
end
