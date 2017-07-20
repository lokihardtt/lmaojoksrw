class Api::V1::ItemsController < ApiController
  skip_before_filter :verify_authenticity_token

  def_param_group :item_param do
    param :item_param, Hash, desc: "Nested parameters of item. Don't use this params." do
      param :id, Integer, desc: "Id of item", required: true
      param :name, String, desc: "item name", required: true
      param :category_ids, Array, desc: "Category of item, and format of category mus be like 'item [category_ids] []'"
      param :descripion, String, desc: "item description"
      param :price, Float, desc: "item price", required: true
      param :currency, String, desc: "item currency"
      param :quantity, Integer, desc: "item quantity", required: true
      param :is_hidden, String, desc: "item is visible for show or no"
      param :galleries_attributes, File, desc: "Image for item, and format of parameter must be like 'item [galleries_attributes] [0] [image]'"
      param :shipping_option_ids, Array, desc: "shipping_option_id for item, and format of parameter 'item [shipping_option_ids] []'"
      param :ship_from, String, desc: "item ship_from"
      param :country_ids, Array, desc: "item ship to, and format of parameter must be like 'item [country_ids] []'"
    end
  end
  
  api :GET, '/v1/items', 'Show items of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def index
    current_user = User.where(authentication_token: params[:auth_token]).first
    @items = current_user.items
    render "api/v1/items/index"
  end

  api :GET, '/v1/copy_item', 'Copy Item'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :item_id, String, desc: "Id of item", required: true
  def copy_item
    item = Item.find(params[:item_id])
    @new_item = item.dup
    @new_item.save
    item.galleries.each do |gallery|
      item_gallery = Gallery.new
      gallery_path = gallery.image.current_path
      if File.exist?(gallery_path)
        item_gallery.image = File.open(gallery_path)
      else
        gallery_url = gallery.image.url
        item_gallery.image = open(URI.parse(gallery_url))
      end
      item_gallery.item_id = @new_item.id
      item_gallery.save
    end
    categories = item.categories
    countries = item.countries
    @new_item.categories << categories
    @new_item.countries << countries

    render "api/v1/items/copy_item"
  end

  api :GET, '/v1/items/:id/edit', 'Edit Item'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :item_id, String, desc: "Id of item", required: true
  def edit
    @item = Item.find(params[:id])
    render "api/v1/items/edit"
  end

  api :POST, '/v1/create_item', "Create item"
  formats ['json']
  param_group :item_param
  def create
    current_user = User.where(authentication_token: params[:auth_token]).first
    params[:item][:user_id] = current_user.id
    item = Item.new(item_params)
    if item.save
      render json: { status: "Item successfully create" }, status: :created
    else
      render json: { errors: item.errors }, status: :unprocessable_entity
    end
  end

  api :POST, '/v1/items/:id', "Update item data"
  formats ['json']
  param_group :item_param
  def update
    item = Item.find(params[:id])
    item_update = item.update_attributes(item_params)
    render json: { status: "item success to update" }, status: :updated
  end

  api :GET, '/v1/change_status', 'Change status of item'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :item_id, String, desc: "Id of item", required: true
  param :item_status, String, desc: "Status of item with value true or false", required: true
  def change_status
    item = Item.find(params[:item_id])
    item.is_hidden = params[:item_status]
    item.save
    render json: { status: "status of item has been change" }, status: :updated
  end

  api :GET, '/v1/destroy_item', 'Destroy item'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :item_id, String, desc: "Id of item", required: true
  def destroy
    item = Item.find(params[:item_id])
    item.destroy
    render json: { status: "item has been deleted" }, status: :updated
  end

  private

  def item_params
    params.require(:item).permit(:name, :description, :price, :ship_from, :is_hidden, :is_up_front_payment, :quantity, :currency, :user_id, galleries_attributes: [:id, :image, :_done, :_destroy], shipping_option_ids: [], category_ids: [], country_ids: [])
  end

end