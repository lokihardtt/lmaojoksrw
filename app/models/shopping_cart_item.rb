class ShoppingCartItem < ActiveRecord::Base
  acts_as_shopping_cart_item
  belongs_to :shipping_option, foreign_key: :shipping_id
end
