class ShoppingCartsController < ApplicationController
  before_action :authenticate_user!
  before_filter :extract_shopping_cart
  before_action :category
  before_action :check_buyer_balance, only: [:create]
  before_action :get_new_price, only: [:encrypt_shipping_information]
  before_action :get_price_from_chart, only: [:pay_page]
  before_action :validate_in_update_cart, only: [:encrypt_shipping_information, :pay_page]
  before_filter :configuration_multisig

  def create
    bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`.to_f
    @item = Item.find(params[:item_id])

    if current_user.role.eql? "Buyer"
      same_vendor = checking_vendor
      if !same_vendor
        redirect_to item_detail_path(random_string: @item.random_string), alert: "Sorry you can't add item from different vendor."
      elsif params[:quantity].to_i < 1
        redirect_to item_detail_path(random_string: @item.random_string, min: true)
      elsif params[:quantity].to_i > @item.quantity
        redirect_to item_detail_path(random_string: @item.random_string, quantity: true)
      else
        @order = @shopping_cart.add_item_to_cart(params[:quantity], params[:shipping], @item, @rates, current_user.id)
        redirect_to item_detail_path(random_string: @item.random_string, shopping_cart_id: @shopping_cart.id, purchase_id: @order.id)
      end
    else
      redirect_to item_detail_path(random_string: @item.random_string), alert: "Sorry Vendor cannot buy or add item to cart"
    end
  end

  def show 
    if @bitcoind_payment_method.status
      @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}` rescue 0
    elsif @blockchain_payment_method.status
      @bitcoin_balance = @wallet.get_balance() rescue 0
    end

    total_price = @shopping_cart.orders.map(&:total_payment).sum
    @total_payment = total_price + @transfer_fee.to_f

    if @total_payment > @bitcoin_balance.to_f 
      flash[:alert] = "Your account has insufficient BTC, please deposit more on Account page"
    end

    if current_user.currency.eql?"United States Dollar"
      current_user.currency = "USD"
    elsif current_user.currency.eql?"Indonesian Rupiah"
      current_user.currency = "IDR"
    end

    group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{current_user.currency}" }
    @local_currency = @bitcoin_balance.to_f * group_local.first['rate'].to_f
  end

  def encrypt_shipping_information
    id = params[:shopping_cart_item_id]
    price = params[:price]
    shipping = params[:shipping]
    quantity = params[:quantity]

    #merge params
    temp = id.merge(price){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    temp1 = temp.merge(shipping){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    hash = temp1.merge(quantity){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    
    over_qty = []
    hash.each do |key, value|
      @shopping_cart_item = ShoppingCartItem.find(value[0])
      item = @shopping_cart_item.item
      item_quantity = item.quantity.to_i + @shopping_cart_item.quantity.to_i

      if item_quantity > value[3].to_i || item.unlimited
        unless item.unlimited
          item.quantity = item_quantity.to_i - value[3].to_i
          item.save
        end

        if (item.currency.eql?"Bitcoin") || (item.currency.eql?"BTC")
          price = item.price * value[3].to_i
        else
          group = @rates.select { |element_hash| element_hash["code"].eql?"#{item.currency}" }
          @price_btc = item.price.to_f / group.first['rate'].to_f
          price = @price_btc * value[3].to_i
        end

        shipping = ShippingOption.find(value[2])

        unless shipping.currency =~ /BTC|Bitcoin/
          if shipping.currency.eql?"United States Dollar"
            currency = "USD"
          elsif shipping.currency.eql?"Indonesian Rupiah"
            currency = "IDR"
          end

          group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{shipping.currency}" }
          @shipping = shipping.price.to_f / group_local.first['rate'].to_f
        end

        total = price + @shipping.to_f
        if value[3].to_i.zero?
          @shopping_cart.remove(item, @shopping_cart_item.quantity)
          order = Order.where(shopping_cart_id: @shopping_cart.id, item_id:  item.id).first
          order.destroy
        else
          @shopping_cart_item.price = total
          @shopping_cart_item.quantity = value[3].to_i 
          @shopping_cart_item.shipping_id = value[2]
          @shopping_cart_item.save
          order = Order.where(shopping_cart_id: @shopping_cart.id, item_id:  item.id).first
          order.quantity = value[3].to_i
          order.total_payment = total
          order.shipping_id = shipping.id
          order.save
        end
      else
        over_qty << item.id
      end
    end

    if over_qty.empty?
      redirect_to shopping_cart_path(success: true)
    else
      redirect_to shopping_cart_path, alert: "Sorry the quantity of this item cannot supply your order"
    end
  end

  def pay_page
    if @shopping_cart.shopping_cart_items.count.zero?
      redirect_to shopping_cart_path, alert: "We are sorry your cart is empty"
    elsif params[:message].present?
      shopping_cart = ShoppingCart.find(params[:shopping_cart_id])
      item = Item.find(params[:item_id])
      file_buyer = File.exists? ("public/pgp/users/#{current_user.id}/key.txt")
      file_vendor = File.exists? ("public/pgp/users/#{item.user.id}/key.txt")
      if file_buyer.present? || file_vendor.present?
        FileUtils.mkdir_p "public/message/cart/#{shopping_cart.id}"
        pgp_key = File.open("public/message/cart/#{shopping_cart.id}/message.txt", 'w') {|f| f.write("#{params[:message]}") }
        url = [Rails.public_path, "/message/cart/#{shopping_cart.id}/message.txt"].join
        
        if file_buyer.present?
          key = `gpg --import "public/pgp/users/#{current_user.id}/publickey.asc" 2>&1`
        else
          key = `gpg --import "public/pgp/users/#{item.user.id}/publickey.asc" 2>&1`
        end
        message = `gpg --recipient #{item.user.username} --encrypt --armor --always-trust #{url} 2>&1`
        read_message = File.open("public/pgp/users/#{user.id}/message.txt.asc") rescue nil
        if read_message.nil?
          params[:message] = params[:message]
        else
          params[:message] = read_message.read.gsub(/\n/, '<br/>')
        end
      end
      additional_informartion_message = AdditionalInformartionMessage.create({ message: params[:message] })
      shopping_cart.additional_information_message_id = additional_informartion_message.id
      shopping_cart.save
      redirect_to pay_order_path(shopping_cart_id: params[:shopping_cart_id], purchase_id: params[:purchase_id])
    else
      redirect_to shopping_cart_path, alert: "Please fill your shipping and additional information"
    end
  end

  def pay_order
    @market_name = MarketName.first
    @shopping_cart = ShoppingCart.find(params[:shopping_cart_id])
    # @qr_status = ApplicationConfiguration.where(name: "QRCode").first.status
    if current_user.id == @shopping_cart.user_id
      if current_user.addresses.present?
        @bitcoin_address = current_user.addresses.where(is_active: true).first.address rescue nil
      else
        address = `bitcoin-cli getaccountaddress #{current_user.username}`.gsub(/\n/, '')
        create_address = Address.create({ address: address, user_id: current_user.id, is_active: true })
        @bitcoin_address = current_user.addresses.where(is_active: true).first.address rescue nil
      end
      @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`
      @escrow_address =  @shopping_cart.orders.first.escrow_address
    else
      redirect_to dashboard_path, alert: "Sorry you can access that page"
    end
  end

  def delete_cart
    shopping_cart_item = ShoppingCartItem.find(params[:id])
    @item = Item.find(shopping_cart_item.item_id)
    @shopping_cart.remove(@item, shopping_cart_item.quantity)
    
    unless @item.unlimited
      new_quantity = @item.quantity + shopping_cart_item.quantity
      @item.update_attributes(quantity: new_quantity)
    end
    
    order = Order.where(shopping_cart_id: @shopping_cart.id, item_id:  @item.id).first
    order.destroy

    redirect_to shopping_cart_path
  end

  def create_multi_sig
    @shopping_cart = ShoppingCart.find(params[:shopping_cart])
    @buyer_address = current_user.addresses.where(is_active: true).first.address rescue nil
    vendor = User.where(username: params[:vendor_name]).first
    @vendor_address = vendor.addresses.where(is_active: true).first.address rescue nil
    @escrow_address = "1E4pCAHJof7bNLJ4eY5jvEefTESYQUnCtQ"
  end

  def generate_multi_sig
    if params[:vendor_pub_key].present? && params[:escrow_pub_key].present?
      @multi_sig, @shopping_cart = ShoppingCart.generate_multi_sig(params)
      redirect_to create_multi_sig_path(multi_sig: @multi_sig, shopping_cart: @shopping_cart.id)
    else
      redirect_to create_multi_sig_path(shopping_cart: @shopping_cart), alert: "We are sorry one of address if nil please tell the vendor to select the active address or you can select one of active address in Profile menu."
    end
  end

  def pay_qr
    
  end

  private
  
  def extract_shopping_cart
    shopping_cart_id = session[:shopping_cart_id]
    @shopping_cart = shopping_cart_id ? ShoppingCart.find(shopping_cart_id) : ShoppingCart.create({ user_id: current_user.id })
    session[:shopping_cart_id] = @shopping_cart.id
  end

  def validate_in_update_cart
    if @bitcoind_payment_method.status.eql?true
      bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`
    elsif @blockchain_payment_method.status.eql?true
      bitcoin_balance = @wallet.get_balance() rescue 0
    end

    if @new_price > bitcoin_balance.to_f 
      redirect_to shopping_cart_path, alert: "Your account has insufficient BTC, please deposit more on Account page"
    end
  end

  def get_new_price
    new_price = []
    id = params[:shopping_cart_item_id]
    quantity = params[:quantity]
    shipping = params[:shipping]
    
    temp = id.merge(quantity){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}
    hash = temp.merge(shipping){|key,oldval,newval| [*oldval].to_a + [*newval].to_a}

    hash.each do |key, value|
      shopping_cart_item = ShoppingCartItem.find(value[0])
      item = shopping_cart_item.item
      if (item.currency.eql?"Bitcoin") || (item.currency.eql?"BTC")
        price = item.price * value[1].to_i
      else
        group = @rates.select { |element_hash| element_hash["code"].eql?"#{item.currency}" }
        @price_btc = (item.price.to_f / group.first['rate'].to_f) *  value[1].to_i
        price = @price_btc 
      end

      shipping = ShippingOption.find(value[2])
      if (shipping.currency.eql?"United States Dollar") || (shipping.currency.eql?"Indonesian Rupiah") || (shipping.currency.eql?"USD") || (shipping.currency.eql?"IDR")
        if shipping.currency.eql?"United States Dollar"
          currency = "USD"
        elsif shipping.currency.eql?"Indonesian Rupiah"
          currency = "IDR"
        end

        group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{shipping.currency}" }
        @shipping = shipping.price.to_f / group_local.first['rate'].to_f
      end

      new_price << price + @shipping.to_f
    end

    @new_price = new_price.sum
  end

  def get_price_from_chart
    shopping_cart = ShoppingCart.find params[:shopping_cart_id]
    @new_price = shopping_cart.shopping_cart_items.sum(:price)
  end

  def check_buyer_balance
    item = Item.find(params[:item_id])

    if current_user.currency.eql?"United States Dollar"
      current_user.currency = "USD"
    elsif current_user.currency.eql?"Indonesian Rupiah"
      current_user.currency = "IDR"
    end

    group = @rates.select { |element_hash| element_hash["code"].eql?"#{item.currency}" }
    group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{current_user.currency}" }

    if (item.currency.eql?"Bitcoin") || (item.currency.eql?"BTC")
      @price = item.price
    else  
      @price = (item.price.to_f / group.first['rate'].to_f) * params[:quantity].to_f
    end
    
    if @shopping_cart.present?
      last_total_price = @shopping_cart.orders.map(&:total_payment).sum.to_f / group_local.first['rate'].to_f
      @price = @price + last_total_price
    end
    
    if @bitcoind_payment_method.status.eql?true
      bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}`
    elsif @blockchain_payment_method.status.eql?true
      bitcoin_balance = @wallet.get_balance() rescue 0
    end

    total_payment = @price + @transfer_fee.to_f

    if bitcoin_balance.to_f < total_payment.to_f
      redirect_to item_detail_url(item.random_string), alert: "Your account has insufficient BTC, please deposit more on Account page"
    end
  end

  def checking_vendor
    item_ids = @shopping_cart.orders.map(&:item_id)
    user_ids = Item.where(id: item_ids).map(&:user_id)

    user_ids.empty? || user_ids.include?(@item.user_id)
  end
end