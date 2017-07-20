class Api::V1::SessionsController < Devise::SessionsController  
  #prepend_before_filter :require_no_authentication, :only => [:create ]
  #include Devise::Controllers::InternalHelpers
  #before_filter :ensure_params_exist, only: :create
  skip_before_filter :verify_authenticity_token

  respond_to :json

  api :POST, '/v1/login', 'user sign in to openfreemarket'
  param :username, String, desc: "User's username", required: true
  param :password, String, desc: "User's password", required: true
  def create
    #build_resource
    if params[:username].blank?
      ensure_params_exist
    else
      resource = User.find_by_username(params[:username])
      if resource
        if resource.valid_password?(params[:password])
          sign_in(:user, resource)
          #resource.ensure_authentication_token!

          render json: {success: true, auth_token: resource.authentication_token, 
            username: resource.username}
          return
        else
          invalid_login_attempt
        end
      else
        invalid_login_attempt
      end
    end
  end

  api :POST, '/v1/logout', "Sign out account"
  def destroy
    sign_out(resource_name)
    render json: {logout: true}
  end

  protected

  def ensure_params_exist
    render json: {success: false, message: "Missing username parameter"}
  end

  def invalid_login_attempt
    warden.custom_failure!
    render json: {success: false, message: "Invalid username or password"}
  end
end