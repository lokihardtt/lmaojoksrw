module ShippingCartsHelper
  def convert_float_to_decimal(price)
    old_price = price.to_s
    new_price = BigDecimal.new(old_price)
    new_price.to_s
  end

  def calculate_total(shopping_cart)
    subtotal = shopping_cart.orders.map(&:total_payment).sum
    subtotal
  end

  def get_item(item_id)
    item = Item.find(item_id)
    item.quantity
  end
end
