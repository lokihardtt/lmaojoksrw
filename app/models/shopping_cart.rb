class ShoppingCart < ActiveRecord::Base
  acts_as_shopping_cart
  belongs_to :additional_informartion_message, foreign_key: :additional_information_message_id
  belongs_to :user
  has_many :orders, dependent: :destroy


  def self.pay_multisig(params, current_user)
    shopping_cart = self.find(params[:shopping_cart])
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f
    shopping_cart.shopping_cart_items.each do |shopping_cart_item|
      orders = Order.where(["date(created_at) = ? AND status = ? AND user_id = ?", Date.today, "Not Pay", current_user.id])
      orders.each do |order|
        order.status = "Pending"
        order.shipping_id = shopping_cart_item.shipping_id
        order.multisig = true
        order.additional_information_message = shopping_cart.additional_informartion_message.message #rescue nil
        multi_sig = MultisigTransaction.where(shopping_cart_id: shopping_cart.id).first
        multi_sig.order_id = order.id
        multi_sig.save
        order.save
      end
    end
    subtotal = shopping_cart.shopping_cart_items.map{ |item| item.quantity*item.price}.sum
    shipping_ids = shopping_cart.shopping_cart_items.map(&:shipping_id)
    if shipping_ids[0].eql? nil
      total = subtotal
    else
      shipping_prices = ShippingOption.find(shipping_ids).map(&:price).sum 
      total = subtotal + shipping_prices
    end
    bitcoin_multisig_address = params[:multisig_address]
    tx_id = `bitcoin-cli sendfrom #{current_user.username} #{bitcoin_multisig_address.gsub(/\n/, '')} #{total} 1 '{ "from" => #{current_user.username}, "to" => #{shopping_cart.shopping_cart_items.first.item.user.username} }' #{shopping_cart.shopping_cart_items.first.item.user.username}`
    # payment = wallet.send('1NAF7GbdyRg3miHNrw2bGxrd63tfMEmJob', 1000000, from_address: '1A8JiWcwvpY7tAopUkSnGuEYHmzGYfZPiq')
    multi_sig = MultisigTransaction.where(shopping_cart_id: shopping_cart.id).first
    multi_sig.tx_id = tx_id
    multi_sig.save
  end

  def self.generate_multi_sig(params)
    shopping_cart = ShoppingCart.find(params[:shopping_cart])
    addresses = []
    publickeys = []
    addresses << params[:vendor_pub_key]
    addresses << params[:buyer_pub_key]
    addresses << params[:escrow_pub_key]
    addresses.each do |address|
      user = `bitcoin-cli validateaddress #{address.gsub(/\n/, '')}`
      user = user.gsub(/\n/, "").gsub(/:/, "=>")
      user = eval(user)
      publickeys << user["pubkey"]
    end
    multi_sig = `bitcoin-cli createmultisig 2 '#{publickeys}'`
    multi_sig = multi_sig.gsub(/\n/, "").gsub(/:/, "=>")
    multi_sig = eval(multi_sig)
    shop_private_key = `bitcoin-cli dumpprivkey #{params[:escrow_pub_key]}`.gsub(/\n/, '')
    buyer_private_key = `bitcoin-cli dumpprivkey #{params[:buyer_pub_key]}`.gsub(/\n/, '')
    MultisigTransaction.create({ address: multi_sig["address"], redeem_script: multi_sig["redeemScript"], vendor_address: params[:vendor_pub_key], buyer_address: params[:buyer_pub_key], escrow_address: params[:escrow_pub_key], shopping_cart_id: shopping_cart.id, shop_pub_key: shop_private_key, buyer_pub_key: buyer_private_key })
    [multi_sig, shopping_cart]
  end

  def pay(params, current_user, rates)
    total = self.orders.map(&:total_payment).sum
    vendor = self.orders.first.item.user
    receiver = "escrow_#{vendor.username}"
    bitcoin_escrow_address = `bitcoin-cli getaccountaddress #{receiver}`.gsub(/\n/, '')
    tx_id = `bitcoin-cli move #{current_user.username} #{receiver} #{total.to_f.round(6)} 1 '{ "from" => #{current_user.username}, "to" => #{receiver}'`
    
    if tx_id.present?
      Transaction.create({ transaction_type: "Pay Order", status: "sent", amount: total.to_f.round(6), username: current_user.username, 
        txid: tx_id, receiver: receiver, order_ids: self.orders.map(&:id).join(",") })
      self.orders.each do |order|
        order.update_attributes(status: "Pending", additional_information_message: self.additional_informartion_message, tx_id: tx_id, item_name: order.product_name)
        order.create_activity action: 'pay', owner: current_user, recipient: order.item.user
      end

      return true
    else
      return false
    end
  end

  def add_item_to_cart(qty, shipping_id, item, rates, user_id)
    new_item_qty = item.quantity - qty.to_i

    if self.shopping_cart_items.map(&:item_id).include? item.id
      current_qty = self.shopping_cart_items.where(item_id: item.id).last.quantity
      quantity = current_qty.to_i + qty.to_i
    else
      quantity = qty.to_i
    end

    if (item.currency.eql? "Bitcoin") || (item.currency.eql? "BTC")
      price = item.price * quantity.to_i
    else
      group = rates.select { |element_hash| element_hash["code"].eql?"#{item.currency}" }
      price_btc = item.price.to_f / group.first['rate'].to_f
      price = price_btc * quantity.to_i
    end

    shipping_option = ShippingOption.find(shipping_id)
    shipping_price = get_shipping_price(shipping_option, rates)
    total = price + shipping_price
    vendor_item = self.shopping_cart_items.first

    self.add(item, total)
    cart_item = self.shopping_cart_items.last
    cart_item.shipping_id = shipping_id
    cart_item.quantity = quantity.to_i
    cart_item.save

    unless item.unlimited
      item.quantity = new_item_qty
      item.save(validate: false)
    end
    escrow_vendor = "escrow_#{item.user.username}"
    escrow = `bitcoin-cli getaccountaddress #{escrow_vendor}`.gsub(/\n/, '')
    order = self.orders.where(item_id: item.id).first
    
    if order
      order.update_attributes({ quantity: qty, total_payment: total.to_f.round(6), shipping_id: shipping_id })
    else
      order = self.orders.create({ user_id: user_id, item_id: item.id, quantity: qty, total_payment: total.to_f.round(6), status: "Not Pay", shipping_id: shipping_id, escrow_address: escrow})
      order.create_activity action: 'create', owner: order.user, recipient: item.user
    end

    order
  end


  def get_shipping_price(shipping_option, rates)
    if shipping_option.currency.eql?("BTC") || shipping_option.currency.eql?("Bitcoin")
      shipping_price = shipping_option.price.to_f
    else
      group_local = rates.select { |element_hash| element_hash["code"].eql?"#{shipping_option.currency}" }
      shipping_price = shipping_option.price.to_f / group_local.first['rate'].to_f
    end
    shipping_price
  end
end
