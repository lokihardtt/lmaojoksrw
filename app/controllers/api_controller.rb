class ApiController < ApplicationController
  before_filter :authenticate_user_from_token!
  before_filter :category
  before_filter :market_name
  before_filter :get_btc_rates
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers
 
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
    headers['Access-Control-Max-Age'] = "1728000"
  end
 
  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
      headers['Access-Control-Max-Age'] = '1728000'
 
      render :text => '', :content_type => 'text/plain'
    end
  end
 
  def get_btc_rates
    currencies = JSON.load(open("https://bitpay.com/api/rates"))
    active_currencies = CurrencyConfig.where(status: true).map(&:name)
    rates = currencies.select{ |hash| active_currencies.include? hash['code'] }
    @rates = rates.each_slice(6).to_a.flatten
  end
  
  def market_name
    @market_name = MarketName.first
    if user_signed_in?
      @message_not_read_count = ConversationsUser.where(receiver_id: current_user.id, is_read: false).count
    end
  end

  def category
    @categories = Category.all
    @ship_from = Item.ship_from_item
    @ship_to = Country.ship_to_item
  end

  private
  # For this example, we are simply using token authentication
  # via parameters. However, anyone could use Rails's token
  # authentication features to get the token from a header.
  def authenticate_user_from_token!
    user_token = params[:auth_token].presence
    user       = user_token && User.find_by_authentication_token(user_token.to_s)
 
    unless user
      render json: { errors: 'user must signed in' }, status: :unprocessable_entity
    end
  end
end