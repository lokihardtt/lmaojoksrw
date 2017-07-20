class Api::V1::OrdersController < ApiController
  skip_before_filter :verify_authenticity_token
  
  api :GET, '/v1/order_list', 'Show all order for vendor'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def order_list
    current_user = User.where(authentication_token: params[:auth_token]).first
    @pendings = current_user.ordered_items.where(status: "Pending").order('created_at ASC')
    @shippeds = current_user.ordered_items.where(status: "Shipped").order('updated_at ASC')
    @sents = current_user.ordered_items.where(status: "Sent").order('updated_at ASC')
    @four_day_ago =  4.days.ago
    render "api/v1/orders/order_list"
  end

  api :GET, '/v1/orders', 'Show all order for buyer'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def index
    current_user = User.where(authentication_token: params[:auth_token]).first
    @not_orders = Order.where(status: "Not Pay",user_id: current_user.id).order('updated_at DESC')
    @pending_orders = Order.where(status: "Pending",user_id: current_user.id).order('updated_at DESC')
    @shipped_orders = Order.where(status: "Shipped",user_id: current_user.id).order('updated_at DESC')
    @sent_orders = Order.where(status: "Sent",user_id: current_user.id).order('updated_at DESC')
    @four_day_ago =  4.days.ago
    render "api/v1/orders/index"
  end

  api :POST, '/v1/finalize_order', 'Change status of order to finalize'
  param :purchase_id, String, desc: "Id of order", required: true
  param :feedback, String, desc: "Feedback about order to vendor"
  param :rating, String, desc: "Give a rating for vendor"
  def finalize_order
    @purchase = Order.finalize(params[:purchase_id], params[:feedback], params[:rating])
    render json: { status: "Your order has been finalize." }, status: :success
  end

  api :GET, '/v1/orders/:id/cancel', 'Cancel order for vendor'
  def cancel_order
    order = Order.cancel(params[:order_id])
    render json: { status: "Your order has been cancel." }, status: :success
  end

  api :GET, '/v1/orders/:id/shipped_order', 'Shipped order for vendor'
  def shipped_order
    order = Order.shipped(params[:order_id])
    render json: { status: "Your order has been approve." }, status: :success
  end

  api :POST, '/v1/sent_order', 'Change status of order to sent'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :tracking_number, String, desc: "Tracking Number of order"
  param :order_id, String, desc: "Id of order"
  def sent_order
    current_user = User.where(authentication_token: params[:auth_token]).first
    vendor_check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{current_user.id}/publickey.asc"].join
    if vendor_check_pgp.eql? true
      order = Order.sent_order(current_user, params, vendor_check_pgp)

      render json: { status: "Your order has been sent." }, status: :success
    else
      render json: { status: "please add your public key to your profile to add tracking number" }, status: :unprocessable_entity
    end
  end

  api :GET, '/v1/form_refund', 'form for refund order'
  param :order_id, String, desc: "Id of order", required: true
  def form_refund
    @order = Order.find(params[:order_id])
    @buyer_address = @order.user.addresses.where(is_active: true).first.address.gsub(/\n/, '')
    render "api/v1/orders/form_refund"
  end

  api :POST, '/v1/refund_order', 'Change status of order to refund and send back BTC to buyer'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :order_id, String, desc: "Id of order"
  param :amount, String, desc: "Amount of BTC will be send back to buyer"
  param :buyer_address, String, desc: "BTC address of buyer"
  def refund_order
    current_user = User.where(authentication_token: params[:auth_token]).first
    order = Order.refund_order(current_user ,params[:order_id], params[:amount], params[:buyer_address].gsub(/\n/, ''))
    render json: { status: "This order already cancel and vendor will be sent back BTC to buyer" }, status: :success
  end

  api :GET, '/v1/form_refund', 'show information btc of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def account
    current_user = User.where(authentication_token: params[:auth_token]).first
    @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f
    @bitcoin_address = current_user.addresses.where(is_active: true).first.address.gsub(/\n/, '')
    unless @bitcoin_address.present? 
      user_address = `bitcoin-cli getaccountaddress #{current_user.username}`.gsub(/\n/, '')
      @bitcoin_address = Address.create({ address: user_address, user_id: current_user.id, is_active: true })
    end
    transactions = JSON.parse `bitcoin-cli listtransactions`
    escrow = transactions.select { |transact_hash| transact_hash["account"].eql?("escrow") && 
      transact_hash["category"].eql?("receive") &&  transact_hash["comment"] && 
      transact_hash["comment"].include?("#{current_user.username}") }.
      map{ |transaction_hash| transaction_hash["amount"] }.sum
    vendor = transactions.select { |transact_hash| transact_hash["account"].eql?("#{current_user.username}") && transact_hash["category"].eql?("receive") &&  transact_hash["comment"] && transact_hash["comment"].include?("#{current_user.username}") }.map{ |transaction_hash| transaction_hash["amount"] }.sum
    @total_amount = escrow - vendor
    @member_price = MemberPrice.first.price
    render "api/v1/orders/account"
  end

  api :GET, '/v1/create_new_bitcoin_address', 'generate new address of BTC'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def create_new_bitcoin_address
    current_user = User.where(authentication_token: params[:auth_token]).first
    new_address = `bitcoin-cli getnewaddress #{current_user.username}`
    bitcoind_user_addresses = current_user.addresses.update_all(is_active: false)
    create_address = Address.create({ address: new_address, user_id: current_user.id, is_active: true })
    render json: { status: "New address success generate. the new address is #{new_address}" }, status: :success
  end

  api :GET, '/v1/member', 'request as member for user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def member
    current_user = User.where(authentication_token: params[:auth_token]).first
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f
    price = MemberPrice.first.price
    if price < bitcoin_balance
      bitcoin_escrow_address = "1E4pCAHJof7bNLJ4eY5jvEefTESYQUnCtQ"
      `bitcoin-cli sendfrom #{current_user.username} #{bitcoin_escrow_address.gsub(/\n/, '')} #{price} 1 '{ "from" => #{current_user.username}, "to" => "admin", "amount" => #{bitcoin_balance}}' "admin"`
      current_user.member = "Pending"
      current_user.save
      render json: { status: "Congratulation you request as member is success, we will tell admin to check it." }, status: :success
    else
      render json: { status: "Sorry your balance is not enought for make member request" }, status: :unprocessable_entity
    end
  end

  api :POST, '/v1/withdraw_funds', 'Withdraw BTC of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :withdraw_password, String, desc: "withdraw password of user"
  param :amount, String, desc: "Amount of BTC will be withdraw"
  param :bitcoin_address, String, desc: "BTC address will receive the btc"
  def withdraw_funds
    current_user = User.where(authentication_token: params[:auth_token]).first
    old_withdraw_password = BCrypt::Password.create(current_user.withdraw_password)
    transactions = JSON.parse `bitcoin-cli listtransactions`
    escrow = transactions.select { |transact_hash| transact_hash["account"].eql?("escrow") && 
      transact_hash["category"].eql?("receive") &&  transact_hash["comment"] && 
      transact_hash["comment"].include?("#{current_user.username}") }.
      map{ |transaction_hash| transaction_hash["amount"] }.sum
    if old_withdraw_password == params[:withdraw_password]
      if params[:amount].to_f <= escrow
        `bitcoin-cli sendfrom escrow #{params[:bitcoin_address].gsub(/\n/, '')} #{params[:amount].to_f} 1 '{ from => "escrow", to => #{current_user.username}}' #{current_user.username}`
        render json: { status: "Congratulation your withdraw success" }, status: :success
      else
        render json: { status: "Sorry your BTC not enough for this transaction" }, status: :unprocessable_entity
      end
    else
      render json: { status: "Sorry your withdraw password not match. Please input the correct password" }, status: :unprocessable_entity
    end
  end

  api :POST, '/v1/transfer_fund', 'Transfer BTC each user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :withdraw_password, String, desc: "withdraw password of user"
  param :amount, String, desc: "Amount of BTC will be withdraw"
  param :bitcoin_address, String, desc: "BTC address will receive the btc"
  def transfer_fund
    current_user = User.where(authentication_token: params[:auth_token]).first
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f
    old_withdraw_password = BCrypt::Password.create(current_user.withdraw_password)
    check_username = JSON.parse `bitcoin-cli getaddressesbyaccount #{params[:bitcoin_address].gsub(/\n/, '')}`
    check_address = `bitcoin-cli getaccount #{params[:bitcoin_address].gsub(/\n/, '')}`
    
    if check_username.empty?
      address = params[:bitcoin_address].gsub(/\n/, '')
      receive = check_address
    else
      address = check_username
      receive = params[:bitcoin_address].gsub(/\n/, '')
    end

    if old_withdraw_password == params["withdraw_password"]
      if params[:amount].to_f <= bitcoin_balance
        `bitcoin-cli sendfrom #{current_user.username} #{address.first.gsub(/\n/, '')} #{params[:amount]} 1 '{ from => #{current_user.username}, to => #{receive}}' receive`
        render json: { status: "Congratulation your transfer BTC success sent to #{receive}" }, status: :success
      else
        render json: { status: "Sorry your BTC is not enought to make a transfer process" }, status: :unprocessable_entity
      end
    else
      render json: { status: "Sorry your withdraw password not match. Please input the correct password" }, status: :unprocessable_entity
    end
  end

  api :GET, 'v1/pay_order_in_order', 'Pay order using button pay now in order for buyer'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :order_id, String, desc: "Id of order", required: true
  param :total, String, desc: "Total payment order", required: true
  def pay_order_in_order
    current_user = User.where(authentication_token: params[:auth_token]).first
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.gsub(/\n/, '').to_f
    
    if bitcoin_balance >= params[:total].to_f
      order = Order.pay_order(params[:order_id], current_user)

      render json: { status: "Congratulations your order is paid. Vendor must now confirm your order." }, status: :success
    else
      render json: { status: "we sorry your bitcoin balance is not enought to pay this order" }, status: :unprocessable_entity
    end
  end
end