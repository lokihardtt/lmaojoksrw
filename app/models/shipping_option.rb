class ShippingOption < ActiveRecord::Base
	belongs_to :user
  has_and_belongs_to_many :items
  has_many :shopping_cart_items, dependent: :destroy, foreign_key: :shipping_id
  has_many :orders, dependent: :destroy, foreign_key: :shipping_id

  validates :name, :price, presence: true
  validates :price, numericality: true

  def self.update_shipping_update(params, rates)
    shipping_option = ShippingOption.find(params[:id])
    old_price = shipping_option.price
    old_currency = shipping_option.currency
    shipping_option.name = params[:shipping_option][:name]
    shipping_option.price = params[:shipping_option][:price]
    shipping_option.currency = params[:shipping_option][:currency]
    shipping_option.save
    if !old_price.eql?(params[:shipping_option][:price]) || !old_currency.eql?(params[:shipping_option][:currency])
      group_local = rates.select { |element_hash| element_hash["code"].eql?"#{shipping_option.currency}" }
      shipping = shipping_option.price.to_f / group_local.first['rate'].to_f
      shipping_option.orders.each do |order|
        item = order.item

        if (item.currency.eql?"Bitcoin") || (item.currency.eql?"BTC")
          price = item.price * order.quantity.to_i
        else
          group = rates.select { |element_hash| element_hash["code"].eql?"#{item.currency}" }
          price_btc = item.price.to_f / group.first['rate'].to_f
          price = price_btc * order.quantity.to_i
        end

        total = price + shipping
        order.update_attributes(total_payment: total)
        shopping_cart_item = shipping_option.shopping_cart_items.where(item_id: item.id).first
        shopping_cart_item.update_attributes(price: total) if shopping_cart_item
      end
    end
  end
end
