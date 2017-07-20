class Api::V1::UsersController < ApiController
  skip_before_filter :authenticate_user_from_token!, only: :create
  skip_before_filter :verify_authenticity_token

  def_param_group :user_update do
    param :user_update, Hash, desc: "Nested parameters of update user. Don't use this params." do
      param :id, Integer, desc: "Id of user", required: true
      param :pin, String, desc: "User PIN"
      param :currency, String, desc: "Currency of user"
      param :locale, String, desc: "Language of system"
      param :password, String, desc: "Password"
      param :password_confirmation, String, desc: "Password confirmation"
      param :fe_policy, String, desc: "fe policy"
      param :description, String, desc: "Description of user"
      param :fee, String, desc: "Fee of user"
      param :public_url, String, desc: "Url of user"
      param :fa_pgp, String, desc: "fa pgp of user"
      param :withdraw_password, String, desc: "Withdraw password of user", required: true
      param :phrase, String, desc: "Phrase of user"
    end
  end

  def_param_group :create_user do
    param :create_user, Hash, desc: "Nested parameters of new user. Don't use this params." do
      param :username, String, desc: "User PIN"
      param :password, String, desc: "Password"
      param :password_confirmation, String, desc: "Password confirmation"
      param :pin, String, desc: "Currency of user"
      param :role, String, desc: "Role of user"
      param :location, String, desc: "Language of system"
      param :currency, String, desc: "fe policy"
    end
  end

  api :POST, '/v1/create_user', "Update user data"
  formats ['json']
  param_group :create_user
  def create
    user = User.new(user_params)
    user.email = "example@example.com"
    user.username = params[:user][:username].encode("utf-8", "ISO-8859-1", :undef => :replace)
    
    if user.save
      user_address = `bitcoin-cli getaccountaddress #{user.username}`.gsub(/\n/, '')
      create_address = Address.create({ address: user_address, user_id: user.id, is_active: true })
      render json: { user: user }, status: :created
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  api :GET, '/v1/users/:id', "Get specific user's and edit data"
  formats ['json']
  param :id, Integer, desc: "User Id", required: true
  def edit
    @user = User.find(params[:id])
    check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{@user.id}/publickey.asc"].join
    if check_pgp.eql? true
      file = File.open("public/pgp/users/#{@user.id}/publickey.asc")
      @publickey = file.read
    end
    render 'api/v1/users/edit'
  end

  api :POST, '/v1/users/:id', "Update user data"
  formats ['json']
  param_group :user_update
  def update
    user = User.find(params[:id])
    if params[:pgp_key].present?
      info = PGP.upload_key(params[:pgp_key], user.id)
    end
    
    if user.withdraw_password.present?
      old_withdraw_password =  BCrypt::Password.create(user.withdraw_password)
    else
      old_withdraw_password =  BCrypt::Password.create(params[:user][:withdraw_password]) 
    end

    if old_withdraw_password == params[:user][:withdraw_password]
      new_password = params[:user][:new_withdraw_password]
      unless new_password.present?
        new_password = params[:user][:withdraw_password]
      end

      params[:user][:withdraw_password] = BCrypt::Password.create(new_password)
      
      user_updated = user.update_attributes(user_update_params)

      if user_updated
        bitcoind_user_address = user.addresses.update_all(is_active: false)
        update_address_bitcoin = Address.find(params[:address])
        update_address_bitcoin.is_active = true
        update_address_bitcoin.save
        render json: user, status: :updated
      else
        render json: { errors: user.errors }, status: :unprocessable_entity
      end
    else
      render json: { errors: "withdraw password not macth" }, status: :unprocessable_entity
    end
  end

  private
  
  def user_params
    params.require(:user).permit(:email, :password, :pin, :role, :location, :currency, :password_confirmation, :username)
  end

  def user_update_params
    params.require(:user).permit(:email, :password, :pin, :role, :location, :currency, :password_confirmation, :username, :locale, :fe_policy, :description, :fee, :public_url, :fa_pgp, :withdraw_password, :phrase)
  end
end