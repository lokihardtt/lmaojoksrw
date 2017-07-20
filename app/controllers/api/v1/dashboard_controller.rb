class Api::V1::DashboardController < ApiController
  impressionist :actions => [:item_detail]

  def_param_group :search_item_for_vendor do
    param :search_item_for_vendor, Hash, desc: "Parameters for do search in vendor dashboard." do
      param :limit, String, desc: "Limit of show item in dashboard"
      param :hours, String, desc: "Show item by activity vendor"
      param :fe, String, desc: "Show item by Fe policy"
      param :sort, String, desc: "Show item by order "
      param :ship_to, String, desc: "Show item by ship to"
      param :ship_from, String, desc: "Show item by ship from"
      param :ship_from, String, desc: "Show item by ship from"
      param :rating, String, desc: "Show item by vendor vendor"
      param :member, String, desc: "Show item by vendor is member or not"
      param :name, String, desc: "Show item by name"
    end
  end

  def_param_group :search_item_for_buyer do
    param :search_item_for_buyer, Hash, desc: "Parameters for do search in buyer dashboard." do
      param :limit, String, desc: "Limit of show item in dashboard"
      param :hours, String, desc: "Show item by activity vendor"
      param :fe, String, desc: "Show item by Fe policy"
      param :sort, String, desc: "Show item by order "
      param :ship_to, String, desc: "Show item by ship to"
      param :ship_from, String, desc: "Show item by ship from"
      param :ship_from, String, desc: "Show item by ship from"
      param :rating, String, desc: "Show item by vendor vendor"
      param :member, String, desc: "Show item by vendor is member or not"
      param :name, String, desc: "Show item by name"
    end
  end

  api :GET, '/v1/dashboard', 'Dashboad Buyer'
  param_group :search_item_for_buyer
  def dashboard
    @items = Item.get_filtered_items_for_buyer(params)
    render "/v1/dashboard/dashboard"
  end

  api :GET, '/v1/dashboard_vendor', 'Dashboad Vendor'
  param_group :search_item_for_vendor
  def dashboard_vendor
    @items = Item.get_filtered_items_for_vendor(params)
    render "api/v1/dashboard/dashboard_vendor"
  end
  
  api :GET, '/v1/countries/:id', 'Show item by category'
  param :id, Integer, desc: "Category Id", required: true
  def item_by_category
    category = Category.find(params[:id])
    @category_items = category.items
    render "api/v1/dashboard/item_by_category"
  end

  api :GET, '/v1/account', 'Show detail of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def show_buyer
    @user = User.where(authentication_token: params[:auth_token]).first
    @bitcoin_address = @user.addresses.where(is_active: true).first.address
    @bitcoin_balance = `bitcoin-cli getbalance #{@user.username}`
    check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{@user.id}/publickey.asc"].join
    if check_pgp.eql? true
      file = File.open("public/pgp/users/#{@user.id}/publickey.asc")
      @publickey = file.read
    end
    render "api/v1/dashboard/show_buyer"
  end

  api :GET, '/v1/item_detail/:id', 'Show detail of item for buyer'
  param :id, String, desc: "Id of item", required: true
  def item_detail
    @item = Item.find(params[:id])
    category = @item.categories.first
    item = Item.where(id: params[:id])
    if category.present?
      @related_items = category.items - item
    end
    @shippings = @item.user.shipping_options.collect{ |shipping_option| ["#{shipping_option.name} (#{shipping_option.price} #{shipping_option.currency})", shipping_option.id]}
    if current_user.role.eql?"Buyer"
      impressionist(@item)
    end
    render "api/v1/dashboard/item_detail"
  end

end