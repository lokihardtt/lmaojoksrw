require 'nokogiri'
require 'open-uri'
require 'gpgme'

class Order < ActiveRecord::Base
  include OrdersHelper
  include PublicActivity::Common

  belongs_to :user
  belongs_to :item
  belongs_to :shopping_cart
  belongs_to :shipping_option, foreign_key: :shipping_id
  has_many :tracking_numbers

  validates :quantity, presence: true
  validates :quantity, numericality: true

  def self.get_order(order_status, user_id, page)
    self.where(status: order_status, user_id: user_id).order('updated_at DESC').page(page)
  end

  def self.auto_cancel_orders
    current_time = Time.now.utc
    auto_finalize_day = ApplicationConfiguration.find(3)
    auto_cancel_day = ApplicationConfiguration.find_by_name("Auto Cancel")
    fiveten_day_ago = current_time - auto_finalize_day.auto_finalize.days
    seventy_hours = current_time - 72.hours
    four_days_ago = current_time - auto_cancel_day.auto_cancel.days
    one_hour = current_time + 1.hours
 
    shopping_carts = ShoppingCart.joins(:orders).where(" orders.status = 'Pending' AND orders.updated_at < ?", four_days_ago)
    shippeds = self.where("status = 'Shipped' AND updated_at < ?", fiveten_day_ago)

    if shopping_carts.present?
      shopping_carts.each do |shopping_cart|
        orders = shopping_cart.orders.where(status: 'Pending')
        total_payment = orders.map(&:total_payment).sum 
        # bitcoin_buyer_address = `bitcoin-cli getaccountaddress #{shopping_cart.user.username}`.gsub(/\n/, '')
        percentage = orders.first.item.user.percentage
        escrow_vendor = "escrow_#{orders.first.item.user.username}"
        tx_id = `bitcoin-cli move #{escrow_vendor} #{shopping_cart.user.username} #{total_payment.to_f.round(6)} 1 '{ "from" => escrow, "to" => #{shopping_cart.user.username}' `
        if tx_id.present?
          Transaction.create({ transaction_type: "Auto Cancel Order", status: "receive", amount: total_payment.to_f.round(6), username: escrow_vendor, 
            txid: tx_id, receiver: shopping_cart.user.username })
          orders.each do |order|
            order.status = "Cancel"
            order.save
            item = order.item
            
            unless item.unlimited
              item.quantity = item.quantity.to_i + order.quantity.to_i
              item.save
            end
          end
        end
      end
    end

    if shippeds.present?
      shippeds.each do |shipped|
        percentage_payment = (percentage/100) * shipped.total_payment.to_f
        amount = shipped.total_payment.to_f - percentage_payment
        # bitcoin_vendor_address = `bitcoin-cli getaccountaddress #{shipped.item.user.username}`
        # bitcoin_vendor_address = bitcoin_vendor_address.gsub(/\n/, '')
        escrow_vendor = "escrow_#{shipped.item.user.username}"
        tx_id = `bitcoin-cli move #{escrow_vendor} #{shipped.item.user.username} #{amount.to_f.round(6)} 1 '{ "from" => escrow, "to" => #{shipped.item.user.username}' `
        
        if tx_id.present?
          Transaction.create({ transaction_type: "Auto Finalize Order", status: "receive", amount: order.amount.to_f.round(6), username: escrow, 
            txid: tx_id, reciever: shipped.item.user.username })
        end
        shipped.status = "Finalize"
        shipped.save
      end
    end

  end

  def self.refund_order(current_user, shopping_cart_id, amount, buyer_address)
    cart = ShoppingCart.find(shopping_cart_id)
    orders = cart.orders.joins(:item).where("items.user_id = ?", current_user.id)
    vendor = orders.first.item.user
    percentage = vendor.percentage
    percentage_payment = (percentage/100) * amount.to_f
    payment = amount.to_f - percentage_payment.to_f
    sender = vendor.status_escrow ? "escrow_#{vendor.username}" : current_user.username
    
    resend_persentage = `bitcoin-cli move admin #{sender} #{percentage_payment.to_f.round(6)} 1 'from admin to #{sender}'`
    refund_transfer = `bitcoin-cli move #{sender} #{orders.first.user.username} #{amount.to_f.round(6)} 1 '{ "from" => #{current_user.username}, "to" => #{orders.first.user.username}' `

    if refund_transfer.present?
      Transaction.create({ transaction_type: "refund Order", status: "receive", amount: amount.to_f.round(6), username: sender, 
        txid: refund_transfer, receiver: orders.first.user.username, order_ids: orders.map(&:id).join(",") })
      orders.each do |order|
        order.status = "Refund"
        order.save
        order.create_activity action: 'refund', owner: order.user, recipient: order.item.user
      end
    end
  end

  def self.sent_order(current_user, params, vendor_check_pgp)
    cart = ShoppingCart.find(params[:order_id])
    orders = cart.orders.joins(:item).where("items.user_id = ?", current_user.id)
    total_payment = orders.map(&:total_payment).sum
    orders.each do |order|
      order.status = "Sent"
      order.shipping_time = Time.now
      order.additional_information_message = ""
      order.save
      order.create_activity action: 'send', owner: order.user, recipient: order.item.user
    end

    cart.additional_informartion_message.delete
    tracking_number_buyer = params[:tracking_number]
    tracking_number = TrackingNumber.create({sender_id: current_user.id, receiver_id: orders.first.user_id, order_id: orders.first.id, tracking_number: tracking_number_buyer})
  end

  def self.pay_order(order_id, current_user)
    cart = ShoppingCart.find(order_id)
    order_ids = cart.orders.map(&:id)
    total_payment = cart.orders.map(&:total_payment).sum
    orders = self.find(order_ids)

    vendor = orders.first.item.user

    receiver = "escrow_#{vendor.username}"
    bitcoin_vendor_address = `bitcoin-cli getaccountaddress #{receiver}`.gsub(/\n/, '')

    tx_id = `bitcoin-cli move #{current_user.username} #{receiver} #{total_payment.to_f.round(6)} 1 '{ "from" => #{current_user.username}, "to" => #{reciever}' `
  
    if tx_id.present?
      Transaction.create({ transaction_type: "Pay Order", status: "receive", amount: amount.to_f.round(6), username: current_user.username, 
        txid: tx_id, receiver: receiver, order_ids: order_ids.join(",") })
    end

    orders.each do |order|
      order.status = "Pending"
      order.shipping_id = shopping_cart_item.shipping_id rescue nil
      order.additional_information_message = shopping_cart.additional_informartion_message.message rescue nil
      total = order.total_payment
      order.tx_id = @tx_id
      order.save
    end
  end

  def self.confirmed(order_id)
    order = self.find(order_id)
    order.status = "Confirmed"
    order.save
  end

  def self.shipped(current_user, shopping_cart_id)
    cart = ShoppingCart.find(shopping_cart_id)
    orders = cart.orders.joins(:item).where("items.user_id = ?", current_user.id)
    total_payment = orders.map(&:total_payment).sum
    vendor = current_user
    percentage = vendor.percentage
    percentage_payment = (percentage/100) * total_payment.to_f
    payment = total_payment.to_f - percentage_payment.to_f

    admin_address = `bitcoin-cli getaccountaddress admin`.gsub(/\n/, '')
    transaction do
      sender = "escrow_#{vendor.username}"
      if vendor.status_escrow
        tx_id_percentage = `bitcoin-cli move #{sender} admin #{percentage_payment.to_f.round(6)} 1 '{ "from" => #{sender}, "to" => admin, "percentage" => true}'`
        if tx_id_percentage
          Transaction.create({ transaction_type: "Percentage to admin", status: "recieve", amount: percentage_payment.to_f.round(6), username: sender, 
            txid: tx_id_percentage, receiver: "admin" })
          orders.each do |order|
            order.ship_order
          end
          return true
        else
          return false
        end
      else
        # vendor_address = `bitcoin-cli getaccountaddress #{vendor.username}`.gsub(/\n/, '')
        tx_id_vendor = `bitcoin-cli move #{sender} #{vendor.username} #{payment.to_f.round(6)} 1 '{ "from" => #{sender}, "to" => #{vendor.username}, "payment" => true}' `

        if tx_id_vendor
          Transaction.create({ transaction_type: "Payment to vendor", status: "recieve", amount: payment.to_f.round(6), username: sender, 
            txid: tx_id_vendor, receiver: vendor.username, order_ids: orders.map(&:id).join(",") })
          
          orders.each do |order|
            order.ship_order
          end
          
          tx_id_percentage = `bitcoin-cli move #{sender} admin #{percentage_payment.to_f.round(6)} 1 '{ "from" => #{sender}, "to" => admin, "percentage" => true}'`
          Transaction.create({ transaction_type: "Percentage to admin", status: "recieve", amount: percentage_payment.to_f.round(6), username: sender, 
            txid: tx_id_percentage, receiver: "admin" })
        else
          return false
        end
      end
    end
  end

  def self.sent(params)
    cart = ShoppingCart.find(params[:order_id])
    orders = cart.orders.joins(:item).where("items.user_id = ?", params[:vendor_id])
    orders.each do |order|
      order.status = "Sent"
      order.shipping_time = Time.now
      order.additional_information_message = ""
      order.save
      order.create_activity action: 'send', owner: order.user, recipient: order.item.user
    end

    cart.additional_informartion_message.delete
  end

  def self.attention(order_id)
    order = self.find(order_id)
    order.status = "Request Buyer Attention"
    order.save
  end

  def self.partially(order_id)
    order = self.find(order_id)
    order.status = "Partially Shipped"
    order.save
  end

  def self.cancel(shopping_cart_id, current_user)
    cart = ShoppingCart.find(shopping_cart_id)
    orders = cart.orders.joins(:item).where("items.user_id = ?", current_user.id)
    total_payment = orders.map(&:total_payment).sum
    buyer = orders.first.user
    # bitcoin_buyer_address = `bitcoin-cli getaccountaddress #{buyer.username}`.gsub(/\n/, '')
    sender = "escrow_#{current_user.username}"
    tx_id = `bitcoin-cli move #{sender} #{buyer.username} #{total_payment.to_f.round(6)} 1 '{ "from" => #{sender}, "to" => #{buyer.username}'`

    if tx_id
      Transaction.create({ transaction_type: "Cancel Order", status: "receive", amount: total_payment.to_f.round(6), username: sender, 
        txid: tx_id, receiver: buyer.username })
      orders.each do |order|
        order.status = "Cancel"
        order.save
        item = order.item
        order.create_activity action: 'cancel', owner: order.user, recipient: item.user

        unless item.unlimited
          item.quantity = item.quantity.to_i + order.quantity.to_i
          item.save
        end
      end

      return true
    else
      return false
    end
    
  end

  def self.finalize(purchase_id, feedback, rating, vendor_id)
    cart = ShoppingCart.find(purchase_id)
    orders = cart.orders.joins(:item).where("items.user_id = ?", vendor_id)
    total_payment = orders.map(&:total_payment).sum

    vendor = User.find(vendor_id)
    if vendor.status_escrow
      percentage = vendor.percentage
      percentage_payment = (percentage/100) * total_payment
      payment = total_payment.to_f - percentage_payment.to_f
      bitcoin_reciever_address = `bitcoin-cli getaccountaddress #{vendor.username}`.gsub(/\n/, '')
      sender = "escrow_#{vendor.username}"

      tx_id = `bitcoin-cli move #{sender} #{vendor.username} #{payment.to_f.round(6)} 1 '{ "from" => #{sender}, "to" => #{vendor.username}'`
      
      if tx_id.present?
        Transaction.create({ transaction_type: "Payment to vendor process", status: "receive", amount: payment.to_f.round(6), username: sender, 
          txid: tx_id, receiver: vendor.username, order_ids: orders.map(&:id).join(",") })
        orders.each do |order|
          order.finalize_order(feedback, rating)
        end
      else
        return false
      end
    else
      orders.each do |order|
        order.finalize_order(feedback, rating)
      end
    end
  end

  def self.get_total_amount(current_user)
    transactions = JSON.parse `bitcoin-cli listtransactions #{current_user.username} 100 0`
    escrow = transactions.select { |transact_hash| transact_hash["account"].eql?("escrow") && 
      transact_hash["category"].eql?("receive") &&  transact_hash["comment"] && 
      transact_hash["comment"].include?("#{current_user.username}") }.
      map{ |transaction_hash| transaction_hash["amount"] }.sum
    vendor = transactions.select { |transact_hash| transact_hash["account"].eql?("#{current_user.username}") && transact_hash["category"].eql?("receive") &&  transact_hash["comment"] && transact_hash["comment"].include?("#{current_user.username}") }.map{ |transaction_hash| transaction_hash["amount"] }.sum
    total_amount = escrow - vendor
  end

  def self.checking_unpaid_order
    orders = Order.where("updated_at < ? AND status = ?", 24.hours.ago, 'Not Pay')
    orders.each do |order|
      if order.user.last_sign_in_at < 24.hours.ago
        item = order.item
        shopping_cart = order.shopping_cart
        new_quantity = item.quantity + order.quantity
        
        shopping_cart.remove(item, order.quantity)
        item.update_attributes(quantity: new_quantity) unless item.unlimited
        order.destroy
      end
    end
  end

  def self.minimum_price
    dollar = BitcoinCurrency.where(code: "USD").first
    9 / dollar.rate
  end

  def finalize_order(feedback, rating)
    self.feedback_comment = feedback
    self.rating = rating
    self.status = "Finalize"
    self.save
    self.create_activity action: 'feedback', owner: self.user, recipient: self.item.user
  end

  def ship_order
    self.status = "Shipped"
    self.confirmation_time = Time.now
    self.save
    self.create_activity action: 'shipped', owner: self.user, recipient: self.item.user
  end

  def price_with_precision
    old_price = self.total_payment.to_s
    new_price = BigDecimal.new(old_price)
    new_price.to_s
  end

  def product_name
    self.item_name.present? ? self.item_name : self.item.name 
  end
end