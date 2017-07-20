require 'bcrypt'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'blockchain'

class OrdersController < InheritedResources::Base
  before_action :authenticate_user!
  before_action :category
  before_filter :configuration_multisig
  before_action :get_user_wallet
  before_filter :get_bitcoin_balance, only: [:pay_order_in_order, :create, :account, :member, :transfer_fund]

  def validate_wallet; end

  def pay_if_fund_not_enough
    if @blockchain_payment_method.status.eql?true
      @escrow_address = "19HSS58CHyF9wve3f1vNhaxxwSqPmvka6H"
    elsif @bitcoind_payment_method.status.eql?true
      @escrow_address = `bitcoin-cli getnewaddress escrow`
    end
    @order = Order.find(params[:order_id])
  end

  def index
    auto_cancel = ApplicationConfiguration.find_by_name("Auto Cancel").auto_cancel
    @four_day_ago =  auto_cancel.days.ago
    @not_orders = Order.get_order("Not Pay", current_user.id, params[:page])
    @pending_orders = Order.get_order("Pending", current_user.id, params[:page])
    @shipped_orders = Order.get_order("Shipped", current_user.id, params[:page])
    @sent_orders = Order.get_order("Sent", current_user.id, params[:page])
  end

  def pay_order_in_order
    if @bitcoin_balance >= params[:total].to_f
      order = Order.pay_order(params[:order_id], current_user)

      redirect_to orders_url, notice: "Congratulations your order is paid. Vendor must now confirm your order."
    else
      redirect_to pay_if_fund_not_enough_url(order_id: params[:order_id])
    end
  end

  def pay
    if current_user.valid_password?(params[:password])
      shopping_cart = ShoppingCart.find(params[:shopping_cart])
      order_cart = shopping_cart.pay(params, current_user, @rates)
      if order_cart
        session.delete(:shopping_cart_id)
        redirect_to orders_url, notice: "Congratulations your order is paid. Vendor must now confirm your order."
      else
        redirect_to pay_order_path(shopping_cart_id: params[:shopping_cart]), alert: "Transaction is failed. Please try again."
      end
    else
      redirect_to pay_order_path(shopping_cart_id: params[:shopping_cart]), alert: "Sorry your password not match"
    end
  end

  def pay_multisig
    bitcoin_multisig_address = params[:multisig_address]
    shopping_cart = ShoppingCart.pay_multisig(params, current_user)

    redirect_to orders_url, notice: "congratulation your already pay this item using multisig. for check you transaction please check this url https://blockchain.info/address/#{bitcoin_multisig_address}, we will tell the vendor and also send the url to vendor to see transaction"
  end

  def create
    item = Item.find(params[:item_id])
    if item.quantity > params[:quantity].to_i
      stock_update = item.quantity - params[:quantity].to_i
      value = item.price * params[:quantity].to_i
      item.quantity = stock_update
      item.save

      order = Order.create({user_id: current_user.id, item_id: item.id, quantity: params[:quantity], total_payment: value, status: "Pending"})
      bitcoin_escrow_address = "1E4pCAHJof7bNLJ4eY5jvEefTESYQUnCtQ"
      
      redirect_to orders_url
    else
      redirect_to item_detail_url(item.id), notice: "Sorry the quantity of this item cannot supply your order"
    end
  end

  def account
    @check_member = ApplicationConfiguration.where(name: "Member").first
    current_user.last_active = Time.now
    current_user.save

    if @blockchain_payment_method.status
      @bitcoin_balance = @wallet.get_balance() rescue nil
      if @bitcoin_balance.present?
        @bitcoin_address = @wallet.list_addresses().first.address
      else
        msg = "you need enable the api key in your wallet" 
      end
    elsif @bitcoind_payment_method.status
      if @bitcoin_balance.present?
        balance_minus_fee
        @bitcoin_address = current_user.addresses.where(is_active: true).first.gsub(/\n/, '')
        
        if @bitcoin_address.nil? 
          user_address = `bitcoin-cli getaccountaddress #{current_user.username}`.gsub(/\n/, '')
          @bitcoin_address = Address.create({ address: user_address, user_id: current_user.id, is_active: true })
        end
      else
        msg = "bitcoin not configured properly on server. bitcoin functions currently unavailable." 
      end
    end
    
    if @bitcoin_balance.present?
      @qr = RQRCode::QRCode.new( "bitcoin:#{@bitcoin_address.address.gsub(/\n/, '')}", :size => 5, :level => :h )
      @member_price = MemberPrice.first.price rescue 10
      group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{current_user.currency}" }
      @local_currency = @bitcoin_balance.to_f * group_local.first['rate'].to_f
    else
      if current_user.role.eql?"Vendor"
        redirect_to dashboard_vendor_path, notice: msg
      elsif current_user.role.eql?"Buyer"
        redirect_to dashboard_path, notice: msg
      end
    end
  end

  def create_new_bitcoin_address
    if @blockchain_payment_method.status
      new_address = @wallet.new_address("new address #{bitcoind_user_addresses.count} of #{current_user.username}") rescue nil
      bitcoind_user_addresses = current_user.addresses.update_all(is_active: false)
      create_address = Address.create({ address: new_address.address, user_id: current_user.id, is_active: true })
    elsif @bitcoind_payment_method.status
      new_address = `bitcoin-cli getnewaddress #{current_user.username}`
      bitcoind_user_addresses = current_user.addresses.update_all(is_active: false)
      create_address = Address.create({ address: new_address, user_id: current_user.id, is_active: true })
    end

    redirect_to bitcoin_account_url
  end

  def member
    current_user.member = "Pending"
    current_user.save
    price = MemberPrice.first.price

    if @blockchain_payment_method.status
      tx_id = @wallet.send('19HSS58CHyF9wve3f1vNhaxxwSqPmvka6H', price, from_address: "#{current_user.username}") rescue nil
    elsif @bitcoind_payment_method.status
      bitcoin_escrow_address = "1E4pCAHJof7bNLJ4eY5jvEefTESYQUnCtQ"
      tx_id = `bitcoin-cli sendfrom #{current_user.username} #{bitcoin_escrow_address.gsub(/\n/, '')} #{price} 1 '{ "from" => #{current_user.username}, "to" => "admin", "amount" => #{@bitcoin_balance}}' "admin"`
    end

    if tx_id.present?
      Transaction.create({ transaction_type: "Request Member", status: "sent", amount: price, username: current_user.username, 
        receiver: "admin", txid: tx_id })
    end
    redirect_to bitcoin_account_url
  end

  def withdraw_funds
    if current_user.valid_password?(params[:password])
      if @blockchain_payment_method.status
        @escrow_address = "19HSS58CHyF9wve3f1vNhaxxwSqPmvka6H"
        payment = @wallet.send('19HSS58CHyF9wve3f1vNhaxxwSqPmvka6H', params[:amount].to_f, from_address: "#{current_user.username}") rescue nil
      elsif @bitcoind_payment_method.status
        tx_id = `bitcoin-cli sendfrom #{current_user.username} #{params[:bitcoin_address].gsub(/\n/, '')} #{params[:amount].to_f} 1 '{ from => "withdraw", to => #{current_user.username}}' #{current_user.username}`
      end

      if tx_id.present?
        Transaction.create({ transaction_type: "Withdraw", status: "sent", amount: params[:amount].to_f, username: current_user.username, 
          receiver: params[:bitcoin_address], txid: tx_id })
        redirect_to bitcoin_account_url, notice: "Congratulation your withdraw success"
      else
        redirect_to bitcoin_account_url, error: "Sorry the transaction is failed"
      end
    else
      redirect_to bitcoin_account_url, notice: "Sorry your withdraw password not match. Please input the correct password"
    end
  end

  def transfer_fund
    receiver_address = `bitcoin-cli getaccountaddress #{params[:bitcoin_address]}`.gsub(/\n/, '')
    check_address = `bitcoin-cli getaccount #{params[:bitcoin_address]}`
    receiver = params[:bitcoin_address]

    if current_user.valid_password?(params["password"])
      if params[:amount].to_f <= @bitcoin_balance.to_f
        if @blockchain_payment_method.status
          @escrow_address = "19HSS58CHyF9wve3f1vNhaxxwSqPmvka6H"
        elsif @bitcoind_payment_method.status
          @escrow_address = `bitcoin-cli getnewaddress escrow`
        end
        tx_id = `bitcoin-cli sendfrom #{current_user.username} #{receiver_address} #{params[:amount]} 1 '{ from => #{current_user.username}, to => #{receiver}}' receiver`
        
        if tx_id.present?
          Transaction.create({ transaction_type: "Other Transaction/Transfer Fund", status: "sent", amount: params[:amount].to_f, username: current_user.username, 
            receiver: receiver, txid: tx_id})
          redirect_to bitcoin_account_url, notice: "Congratulation your transfer BTC success sent to #{receive}"
        else
          redirect_to bitcoin_account_url, error: "Sorry the transaction is failed"
        end
      else
        redirect_to bitcoin_account_url, error: "Sorry your BTC is not enough to make a transfer process"
      end
    else
      redirect_to bitcoin_account_url, error: "Sorry your transaction password not match. Please input the correct password"
    end
  end

  def order_detail
    @order = Order.find(params[:id])
  end

  def order_list
    @pendings = current_user.get_pending_orders(params[:page])
    @shippeds = current_user.get_shipped_orders(params[:page])
    @sents = current_user.get_sent_orders(params[:page])
    auto_cancel = ApplicationConfiguration.find_by_name("Auto Cancel").auto_cancel
    @four_day_ago =  auto_cancel.days.ago
  end

  def waiting_list
    @pendings = current_user.ordered_items.where(status: "Pending").order('created_at ASC').page(params[:page])
    @shippeds = current_user.ordered_items.where(status: "Shipped").order('created_at ASC').page(params[:page])
    session[:new_shopping_cart_ids] = @pendings.map { |p| p.shopping_cart_id }.uniq
    render layout: "waiting_list"
  end

  def sent_order
    vendor_check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{current_user.id}/publickey.asc"].join
    if vendor_check_pgp
      order = Order.sent_order(current_user, params, vendor_check_pgp)

      redirect_to orders_list_url
    else
      redirect_to orders_list_url, alert: "please add your public key to your profile to add tracking number"
    end
  end

  def approve_and_sent_orders
    shopping_carts = ShoppingCart.where(id: session[:new_shopping_cart_ids])
    session[:new_shopping_cart_ids].each do |shopping_cart_id|
      Order.shipped(current_user, shopping_cart_id)
    end

    shipped_orders = current_user.ordered_items.where(status: "Shipped")
    shipped_orders.update_all(status: "Sent", shipping_time: Time.now)
    shipped_orders.each do |so|
      tracking_number = TrackingNumber.create({sender_id: current_user.id, receiver_id: orders.first.user_id, order_id: orders.first.id, tracking_number: params[:tracking_number]})
    end

    redirect_to orders_list_url
  end

  def confirm_order
    order = Order.confirmed(params[:order_id])

    redirect_to orders_list_url
  end

  def shipped_order
    order = Order.shipped(current_user, params[:order_id])
    msg = order ? "Confirmation Shipping success!" : "Confirmation shipping failed. Please wait 10-15 minutes to make sure the transaction is success"
    redirect_to orders_list_url, notice: msg
  end

  def request_buyer_attention_order
    order = Order.attention(params[:order_id])

    redirect_to orders_list_url
  end

  def partially_shipped_order
    order = Order.partially(params[:order_id])

    redirect_to orders_list_url
  end

  def finalize_order
    if params[:feedback].present?
      @purchase = Order.finalize(params[:purchase_id], params[:feedback], params[:rating], params[:vendor_id])
      if @purchase 
        notice = "Send feedback success!"
      else
        alert = "Send feedback failed. Please wait 10-15 minutes to make sure the transaction is success"
      end
    else
      alert = "Must enter text for Leave Feedback"
    end

    redirect_to orders_url, alert: alert, notice: notice
  end

  def cancel
    order = Order.cancel(params[:order_id], current_user)
    session.delete(:shopping_cart_id)
    if order
      msg = "This order already cancel and vendor will be sent back BTC to buyer"
    else
      msg = "There is error occured. Please try again"
    end
    
    redirect_to orders_list_url, notice: msg
  end

  def refund_order
    order = Order.refund_order(current_user, params[:shopping_cart_id], params[:amount], params[:buyer_address])
    if order
      msg = "This order already cancel and vendor will be sent back BTC to buyer"
    else
      msg = "There is error occured. Please try again"
    end
    
    redirect_to orders_list_url, notice: msg
  end

  def form_refund
    @shopping_cart = ShoppingCart.find(params[:shopping_cart_id])
    orders = @shopping_cart.orders.joins(:item).where("items.user_id = ?", current_user.id)
    @total_payment = orders.map(&:total_payment).sum
    @buyer_address = orders.first.user.addresses.where(is_active: true).first.address.gsub(/\n/, '')
  end

  private

    def get_bitcoin_balance
      @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f rescue nil
      @balance = @wallet.get_balance rescue nil

      if @bitcoind_payment_method.status
        @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}` rescue 0
      elsif @blockchain_payment_method.status
        @bitcoin_balance = @wallet.get_balance() rescue 0
      end

      if (current_user.currency.eql? "United States Dollar") || (current_user.currency.eql? "Indonesian Rupiah") || (current_user.currency.eql? "USD") || (current_user.currency.eql? "IDR")
        if current_user.currency.eql? "United States Dollar"
          current_user.currency = "USD"
        elsif current_user.currency.eql? "Indonesian Rupiah"
          current_user.currency = "IDR"
        end

        group_local = @rates.select { |element_hash| element_hash["code"].eql? "#{current_user.currency}" }
        @local_currency = @bitcoin_balance.to_f * group_local.first['rate'].to_f
      end
    end

    def balance_minus_fee
      if @bitcoin_balance.to_f <= 0.0009
        @bitcoin_balance = @bitcoin_balance.to_f - 0.00006060
      elsif @bitcoin_balance.to_f <= 0.009
        @bitcoin_balance = @bitcoin_balance.to_f - 0.00002000
      elsif @bitcoin_balance.to_f <= 0.09
        @bitcoin_balance = @bitcoin_balance.to_f - 0.00001000
      end
    end
end