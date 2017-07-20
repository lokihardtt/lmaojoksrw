class Api::V1::ShippingOptionsController < ApiController
  skip_before_filter :verify_authenticity_token

   def_param_group :update_shipping_option_param do
    param :update_shipping_option_param, Hash, desc: "Nested parameters of update shipping_options. Don't use this params." do
      param :id, Integer, desc: "Id of shipping_options", required: true
      param :name, String, desc: "shipping_option_param name", required: true
      param :price, Float, desc: "shipping_option_param price", required: true
      param :currency, String, desc: "shipping_option_param currency"
    end
  end

  api :GET, '/v1/shipping_options', 'Show all shipping options of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def index
    current_user = User.where(authentication_token: params[:auth_token]).first
    @shipping_options = current_user.shipping_options
    render 'api/v1/shipping_options/index'
  end

  api :GET, '/v1/shipping_options/:id/edit', 'Edit Shipping Option'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :id, String, desc: "Id of shipping option", required: true
  def edit
    @shipping_option = ShippingOption.find(params[:id])
    render 'api/v1/shipping_options/edit'
  end


  def create
    params[:shipping_option][:user_id] = User.where(authentication_token: params[:auth_token]).first.id
    shipping_option =  ShippingOption.create({ name: params[:shipping_option][:name], price: params[:shipping_option][:price], currency: params[:shipping_option][:currency], user_id: params[:shipping_option][:user_id] })
    if shipping_option
      render json: { status: "Shipping Option has been create" }, status: :created
    else
      render json: { errors: shipping_option.errors }, status: :unprocessable_entity
    end
  end

  api :POST, '/v1/shipping_options/:id', "Update Shipping Option"
  formats ['json']
  param_group :update_shipping_option_param
  def update
    shipping_option = ShippingOption.find(params[:id])
    shipping_option = shipping_option.update_attributes(shipping_option_params)
    if shipping_option
      render json: { status: "Shipping Option has been update" }, status: :updated
    else
      render json: { errors: shipping_option.errors }, status: :unprocessable_entity
    end
  end

  private

  def shipping_option_params
    params.require(:shipping_option).permit(:name, :price, :currency, :user_id)
  end
end