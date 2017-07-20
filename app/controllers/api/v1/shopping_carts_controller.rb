class Api::V1::ShoppingCartsController < ApiController
  skip_before_filter :verify_authenticity_token
  before_filter :extract_shopping_cart

  api :POST, '/v1/shopping_cart', 'Create a order'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :shopping_cart_id, String, desc: "Id of shopping cart"
  param :item_id, String, desc: "Id of item"
  param :quantity, String, desc: "Quantity item will be order"
  param :shipping, String, desc: "Shipping of order"
  def create
    current_user = User.where(authentication_token: params[:auth_token]).first
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`
    @item = Item.find(params[:item_id])
    if params[:quantity].to_i < 1
      render json: { status: "Sorry your quantity order must be equal 1 or higger than 1" }, status: :unprocessable_entity
    else
      new_quantity = @item.quantity - params[:quantity].to_i
      price = @item.price * params[:quantity].to_i
      shipping = ShippingOption.find(params[:shipping]).price
      total = price + shipping
      if params[:quantity].to_i > @item.quantity
        render json: { status: "Sorry the quantity of item cannot process your order." }, status: :unprocessable_entity
      # elsif total >= bitcoin_balance.to_f
      #   render json: { status: "Sorry you bitcoin balance is not enough for buy this item." }, status: :unprocessable_entity
      elsif params[:shopping_cart_id].present?
        shopping_cart = ShoppingCart.find(params[:shopping_cart_id])
        vendor_item = shopping_cart.shopping_cart_items.first
        if @item.user.username === vendor_item.item.user.username
          @shopping_cart.add(@item, @item.price)
          cart_item = @shopping_cart.shopping_cart_items.last
          cart_item.shipping_id = params[:shipping]
          cart_item.save
          @item.quantity = new_quantity
          @item.save
          @order = Order.create({user_id: current_user.id, item_id: params[:item_id], quantity: params[:quantity], total_payment: total, status: "Not Pay", shipping_id: params[:shipping]})
          render json: { status: "Order successfully create" }, status: :created
        elsif @item.user.name != vendor_item.item.user.username
          render json: { status: "Sorry for now we cann't handle for multiple vendor. Please select item with same vendor with you first item in your cart." }, status: :unprocessable_entity
        end
      else
        @shopping_cart.add(@item, @item.price)
        cart_item = @shopping_cart.shopping_cart_items.last
        cart_item.shipping_id = params[:shipping]
        cart_item.save
        @item.quantity = new_quantity
        @item.save
        @order = Order.create({user_id: current_user.id, item_id: params[:item_id], quantity: params[:quantity], total_payment: total, status: "Not Pay", shipping_id: params[:shipping]})
        render json: { status: "Order successfully create", shopping_cart_id: @shopping_cart.id }, status: :created
      end
    end
  end

  api :GET, '/v1/shopping_cart', 'Show shopping cart item'
  param :shopping_cart_id, String, desc: "Id of shopping cart"
  def show
    @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`
    render 'api/v1/shopping_carts/show'
  end

  api :POST, '/v1/shopping_carts/update_order', 'Create a order'
  param :shopping_cart_id, String, desc: "Id of shopping cart"
  param :shopping_cart_item_id, Hash, desc: "Id of shopping cart item, params must be like shopping_cart_id [n], n start from 1"
  param :price, Hash, desc: "Price of item, params must be like price [n], n start from 1"
  param :quantity, Hash, desc: "Quantity item will be order, params must be like quantity [n], n start from 1"
  param :shipping, Hash, desc: "Shipping of order, params must be like shipping [n], n start from 1"
  def update_order
    id = params[:shopping_cart_item_id]
    price = params[:price]
    shipping = params[:shipping]
    quantity = params[:quantity]

    #merge params
    temp = id.merge(price){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    temp1 = temp.merge(shipping){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    hash = temp1.merge(quantity){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}

    hash.each do |key, value|
      @shopping_cart_item = ShoppingCartItem.find(value[0])
      puts value[1]
      puts value[1].eql?(0)
      puts value[1].blank?
      unless value[1].to_i.zero? || value[1].blank?
        @shopping_cart_item.price = value[1]
      end
      @shopping_cart_item.quantity = value[3]
      @shopping_cart_item.shipping_id = value[2]
      @shopping_cart_item.save
    end
    render json: { status: "Your cart already updated" }, status: :created
  end

  api :POST, '/v1/shopping_carts/message_information', 'Create a message information'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :shopping_cart_id, String, desc: "Id of shopping cart"
  param :message, String, desc: "Addtional Message"
  def message_information
    current_user = User.where(authentication_token: params[:auth_token]).first
    # item = Item.find(params[:item_id])
    # file_buyer = File.exists? ("public/pgp/users/#{current_user.id}/key.txt")
    # file_vendor = File.exists? ("public/pgp/users/#{item.user.id}/key.txt")
    
    # if file_buyer.present?
    #   email = nil
    #   key = `gpg --import "public/pgp/users/#{current_user.id}/publickey.asc" 2>&1`
    # else
    #   email = nil
    #   key = `gpg --import "public/pgp/users/#{item.user.id}/publickey.asc" 2>&1`
    # end
    # key.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| email = x }
    # crypto = GPGME::Crypto.new(:armor => true, :always_trust => true)
    
    # if email.present?
    #   params[:message] = crypto.encrypt "#{params[:message]}", :recipients => "#{email}"
    # else
    #   params[:message] = crypto.encrypt "#{params[:message]}"
    # end  
    # params[:message] = params[:message].read
    additional_informartion_message = AdditionalInformartionMessage.create({ message: params[:message] })

    shopping_cart = ShoppingCart.find(params[:shopping_cart_id])
    shopping_cart.additional_information_message_id = additional_informartion_message.id
    shopping_cart.save
    render json: { status: "Your additional information already created" }, status: :created
  end

  api :GET, '/v1/pay', 'Pay order'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :shopping_cart, String, desc: "id of shopping cart"
  def pay
    current_user = User.where(authentication_token: params[:auth_token]).first
    shopping_cart = ShoppingCart.pay(params, current_user)

    render json: { status: "Congratulations your order is paid. Vendor must now confirm your order." }, status: :created
  end

  api :POST, '/v1/delete_cart/:id', "Delete order in cart"
  param :shopping_cart, String, desc: "id of shopping cart"
  param :id, String, desc: "id of shopping cart item"
  def delete_cart
    shopping_cart_item = ShoppingCartItem.find(params[:id])
    @item = Item.find(shopping_cart_item.item_id)
    @shopping_cart.remove(@item, shopping_cart_item.quantity)
    render json: { status: "Your order has been deleted" }, status: :deleted
  end

  private
  def extract_shopping_cart
    shopping_cart_id = params[:shopping_cart_id]
    @shopping_cart = params[:shopping_cart_id] ? ShoppingCart.find(shopping_cart_id) : ShoppingCart.create
    session[:shopping_cart_id] = @shopping_cart.id
  end
end