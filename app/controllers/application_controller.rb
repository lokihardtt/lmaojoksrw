class ApplicationController < ActionController::Base

  include SimpleCaptcha::ControllerHelpers
  protect_from_forgery with: :exception
  before_action :set_i18n_locale_from_params
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :market_name
  before_action :get_btc_rates
  before_action :check_invite_user
  before_action :get_user_wallet
  before_action :check_payment_method
  before_action :check_en_languange
  before_action :check_id_languange
  before_action :check_cart
  before_action :check_last_order_status
  before_action :check_order
  before_action :check_disabled_link

  before_action do  
    resource = controller_name.singularize.to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end

  protected
    def check_last_order_status
      if user_signed_in?
        last_cart = current_user.shopping_carts.order('created_at ASC').last
        if last_cart
          last_order_status = last_cart.orders.last.status if last_cart.orders.present?
          if last_order_status && last_order_status.eql?("Not Pay")
            session[:shopping_cart_id] = last_cart.id
          end
        end
      end
    end

    def check_en_languange
      @check_en_languange = Language.where(name: "EN").first.status
    end

    def check_id_languange
      @check_id_languange = Language.where(name: "ID").first.status
    end

    def check_cart
      if session[:shopping_cart_id].present?
        @cart = ShoppingCart.find(session[:shopping_cart_id])
      end
    end

    def check_order
      if user_signed_in? && current_user.role.eql?("Vendor")
        @order_count = current_user.ordered_items.where(status: ['Pending', 'Shipped']).count
      end
    end

    def check_payment_method
      @bitcoind_payment_method = ApplicationConfiguration.where(name: "bitcoind").first
      @blockchain_payment_method = ApplicationConfiguration.where(name: "Blockchain").first
    end

    def get_user_wallet
      if user_signed_in? && current_user.blockchain_password.present?
        @wallet = Blockchain::Wallet.new("#{current_user.identifier}", "#{current_user.blockchain_password}")
      end
    end

    def configuration_multisig
      @multisig = ApplicationConfiguration.first
    end

    def check_invite_user
      @check_invite_buyer = ApplicationConfiguration.get_invite_buyer_status
      @check_invite_vendor = ApplicationConfiguration.get_invite_vendor_status
    end

    def configuration_invite
      @invite = ApplicationConfiguration.get_invite_buyer_status
      
      if @invite.blank? || !@invite.status
        redirect_to dashboard_vendor_path, notice: "This feature is disable in admin"
      end
    end

    def get_btc_rates
      bc_last_updates = BitcoinCurrency.last.updated_at if BitcoinCurrency.last
      BitcoinCurrency.reset_currencies if bc_last_updates < 1.minute.ago || bc_last_updates.blank?
      currencies = BitcoinCurrency.all
      active_currencies = CurrencyConfig.get_currency_with_status_true
      @rates = currencies.select{ |hash| active_currencies.include? hash['code'] }
    end
    
    def market_name
      @market_name = MarketName.first
      @message_not_read_count = ConversationsUser.count_unread_message(current_user) if user_signed_in?
    end

    def set_i18n_locale_from_params
      if params[:locale]
        if I18n.available_locales.map(&:to_s).include?(params[:locale])
          I18n.locale = params[:locale]
        else
          flash.now[:notice] = "#{params[:locale]} translation not available"
          logger.error flash.now[:notice]
        end
      end
    end
    
    def default_url_options
      { locale: I18n.locale }
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :pin, :role, :location, :currency, :password_confirmation, :username, :string_indentifier) }
      devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:email, :password, :username, :remember_me) }
      devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, :password, :pin, :role, :location, :currency, :password_confirmation, :username, :locale, 
        :fe_policy, :description, :fee, :public_url, :fa_pgp, :withdraw_password, :phrase, :string_indentifier, :vacation_mode) }
    end

    def after_sign_in_path_for(resource)
      if resource.is_a?(AdminUser)
        admin_dashboard_path
      else
        I18n.locale = resource.locale.downcase if resource.is_a?(User) && resource.locale.present?

        if resource.role.eql?("Buyer")
          dashboard_path
        elsif resource.role.eql?("Support")
          private_messages_path
        else
          dashboard_vendor_path
        end
      end
    end

    def check_vendor
      redirect_to dashboard_path unless current_user.role.eql?("Vendor")
    end

    def category
      @categories = Category.all
      @uncategories = Item.get_uncategories_items
      @ship_from = Item.ship_from_item
      @ship_to = Country.ship_to_item
    end

    def check_disabled_link
      @support_link = OptionLink.where(link: "Support").first
    end

    def transfer_fee
      @shopping_cart = ShoppingCart.find(session[:shopping_cart_id]) if @shopping_cart.blank?
      
      unless @shopping_cart.orders.empty?
        total_payment = @shopping_cart.orders.map(&:total_payment).sum.to_f
        @transfer_fee = if total_payment <= 0.0008
          (total_payment / 0.5)
        elsif total_payment <= 0.005
          (total_payment / 5)
        elsif total_payment <= 0.009
          (total_payment / 50) 
        elsif total_payment <= 0.05
          (total_payment / 500) * 2
        else
          (total_payment / 1000) * 2
        end
      end
    end
end