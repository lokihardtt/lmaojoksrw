require 'open-uri'

class ItemsController < InheritedResources::Base
  before_action :authenticate_user!
  before_action :check_vendor, except: :vendor_item
  before_action :categories
  before_action :category
  before_action :option_select, only: [:new, :edit, :create, :update]
  before_action :fetch_item, only: [:edit, :destroy, :show, :update]

  def index
    @items = current_user.items.order("id ASC").page(params[:page]).per(10)
  end

  def vendor_item
    @user = User.find(params[:vendor_id])
  end

  def shipping_option_list
    @shipping_options = current_user.shipping_options
  end

  def edit
    @countries = Country.all.order("name ASC")
    @item.galleries.build
    @shipping_options = current_user.shipping_options
    @currency = CurrencyConfig.get_currency_with_status_true
  end

  def confirm_delete
    if params[:item_id].present?
      @item = Item.find(params[:item_id])
    else
      @shipping_option = ShippingOption.find(params[:shipping_option_id])
    end
  end

  def destroy
    @item.destroy
    redirect_to items_path, notice: "The item already deleted"
  end

  def destroy_shipping_option
    shipping_option = ShippingOption.find(params[:id])
    shipping_option.destroy
    redirect_to shipping_option_list_path, notice: "The shipping option already deleted"
  end

  def show
    redirect_to dashboard_vendor_path, alert: "Sorry Vendor cannot buy items" unless current_user.id.eql?(@item.user_id)
  end

  def new
    @item = Item.new
    @countries = Country.all.order("name ASC")
    @item.galleries.build
    @shipping_options = current_user.shipping_options
    @currency = CurrencyConfig.get_currency_with_status_true
  end

  def create
    @item = Item.new(item_params)
    @item.check_currency_item_price

    if @item.save
      redirect_to items_path, notice: "Success for add a new item"
    else
      render action: 'new', notice: "#{@item.errors.messages}"
    end
  end

  def update
    @item.update(item_params)

    if @item.save
      redirect_to items_path, notice: "Success for Update item"
    else
      @currency = CurrencyConfig.get_currency_with_status_true
      render action: 'edit', notice: "Something wrong"
    end
  end

  def shipping_option_edit
    @shipping_option = ShippingOption.find(params[:id])
  end

  def shipping_option_new
    @shipping_option = ShippingOption.new
  end

  def create_shpping_option_new
    @shipping_option =  ShippingOption.create({ name: params[:shipping_option][:name], price: params[:shipping_option][:price], currency: params[:shipping_option][:currency], user_id: params[:shipping_option][:user_id] })

    redirect_to shipping_option_list_path, notice: "Shipping option added"
  end

  def update_shipping_options
    @shipping_option = ShippingOption.update_shipping_update(params, @rates)

    redirect_to shipping_option_list_path, notice: "Shipping option updated"
  end

  def copy_item
    item = Item.duplicate_item(params)

    redirect_to items_path, notice: "Item succesfully copied"
  end

  def change_status
    item = Item.change_status(params)

    redirect_to items_path, notice: "Status of item already change"
  end

  private

  def option_select
    head_category = ["My Groups"]
    head_all = ["All Groups"]
    head_country = ["Common Country"]
    head_all_country = ["All Country"]

    current_categories = current_user.items.map{ |item| item.categories.map { |category| [category.name, category.id] } }.flatten(1).uniq
    current_categories = [["--No Category--", ""]] if current_categories.blank?
    
    @my_categories = head_category << current_categories
    all_categories = Category.where.not(id: current_categories.map(&:last))
    @all_categories = head_all << all_categories.map { |category| [category.name, category.id]}
    
    current_country = current_user.items.map{ |item| item.countries.order("name ASC").map { |country| [country.name, country.id] } }.flatten(1).uniq
    current_country = [["--No Country--", ""]] if current_country.blank? 

    @my_countries = head_country << current_country
    all_country = Country.where.not(id: current_country.map(&:last))
    @all_country = head_all_country << all_country.order("name ASC").map { |country| [country.name, country.id]}
  end

  def image_params
    params.require(:item).permit(galleries_attributes: [:id, :image, :_done, :_destroy])
  end

  def shipping_option_params
    params.require(:shipping_option).permit(:name, :price, :currency, :user_id)
  end

  def item_params
    params[:item][:quantity] = 1000 if params[:item][:unlimited].eql?("1")
    params[:item][:description] = params[:item][:description].gsub(/\n/, '<br/>')
    params.require(:item).permit(:name, :description, :price, :ship_from, :is_hidden, :is_up_front_payment, :quantity, :unlimited, :currency, :user_id, galleries_attributes: [:id, :image, :_done, :_destroy], shipping_option_ids: [], category_ids: [], country_ids: [])
  end

  def categories
    @categories = Category.all.map { |category| [category.name, category.id]}
  end

  def fetch_item
    @item = Item.find(params[:id])
  end
end
