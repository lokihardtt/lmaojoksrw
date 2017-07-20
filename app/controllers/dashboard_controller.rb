require 'httparty'
class DashboardController < ApplicationController
  impressionist actions: [:index]
  before_action :authenticate_user!
  before_action :category
  before_action :seventy_two_hours_ago, only: [:item_by_category, :uncategories_items]
  impressionist actions: [:item_detail]

  def list_country
    @countries = Country.all
  end

  def show_item_by_country
    @country = Country.find(params[:country_id])
    @ship_tos = @country.items
    @ship_froms = Item.where(ship_from: params[:country_id])
  end

  def dashboard
    @countries = Country.all.collect { |country| ["#{country.name}", country.id] }
    params[:country] = current_user.location.to_i    
    @items = Item.qty_available.get_filtered_items(params)
  end

  def dashboard_vendor
    dashboard
  end

  def show_buyer
    @user = current_user
    @bitcoin_address = @user.addresses.where(is_active: true).first.address.gsub(/\n/, '')
    @bitcoin_balance = @bitcoind_payment_method.status ? `bitcoin-cli getbalance #{current_user.username}` : @wallet.get_balance()

    check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{@user.id}/publickey.asc"].join
    if check_pgp
      file = File.open("public/pgp/users/#{@user.id}/publickey.asc")
      publickey = file.read
      @publickey = publickey.gsub(/\r\n/, '<br/>')
    end
  end

  def item_detail
    @item = Item.where(random_string: params[:random_string]).first
    item = Item.where(id: params[:id])
    category = @item.categories.first if @item

    @related_items = category.items - item if category.present?
    
    shippings = @item.user.shipping_options.collect { |shipping_option| ["#{shipping_option.name} (#{shipping_option.price} #{shipping_option.currency})", shipping_option.id] }
    data_collect = []
    data_first = []
    data_last = []

    shippings.each do |shipping|
      if shipping[0].downcase.include?("free")
        data_first << shipping
      else
        data_last << shipping
      end
      data_collect = data_first + data_last
    end
    @data = data_collect.uniq

    if current_user.role.eql?"Buyer"
      impressionist(@item)
    end

    @orders = @item.orders.where("feedback_comment IS NOT NULL").page(params[:page]).per(25)
  end

  def item_by_category
    @category = Category.find(params[:id])
    category_items = @category.items.joins(:countries, :user)
    @category_items = set_category_items(category_items)
  end

  def uncategories_items
    uncategories_items = Item.get_uncategories_items.joins(:countries, :user)
    @uncategories_items = set_category_items(uncategories_items)
  end

  def show_full_image
    @item = Item.where(random_string: params[:random_string]).first
    render layout: false
  end

  private

  def set_category_items(ci)
    country_id = current_user.location.to_i
    categories_items = 
      if country_id.zero?
        ci.where("users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE AND items.quantity > 0 ", @seventy_two_hours_ago)
      else
        ci.where("users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE AND items.quantity > 0 AND countries.id = ? ", @seventy_two_hours_ago, country_id)
      end

    categories_items
  end

  def seventy_two_hours_ago
    current_time = Time.now.utc
    @seventy_two_hours_ago = current_time - 72.hours
  end
end