class Users::SessionsController < Devise::SessionsController
  prepend_before_filter :require_no_authentication, only: [ :new, :create ]
  prepend_before_filter :allow_params_authentication!, only: :create
  prepend_before_filter :verify_signed_out_user, only: :destroy
  prepend_before_filter only: [ :create, :destroy ] { request.env["devise.skip_timeout"] = true }
  skip_before_filter :verify_authenticity_token

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    respond_with(resource, serialize_options(resource))
  end

  # POST /resource/sign_in
  def create
    if simple_captcha_valid?
      if params[:user][:password].present?
        user = User.where(username: params[:user][:username]).first
        if user && user.fa_pgp
          sign_out @user
          redirect_to input_string_path(username: params[:user][:username], id_auth: "2fa")
        else
          self.resource = warden.authenticate!(auth_options)
          set_flash_message(:notice, :signed_in) if is_flashing_format?
          sign_in(resource_name, resource)
          bitcoin_user_addresses = current_user.addresses.first
          unless bitcoin_user_addresses.present?
            user_addresses = `bitcoin-cli getaddressesbyaccount #{current_user.username}`
            if user_addresses.present?
              if user_addresses.eql?"[\n]\n"
                current_user.addresses.update_all(is_active: false)
                user_addresses = `bitcoin-cli getaccountaddress #{current_user.username}`.gsub(/\n/, '')
                bitcoin_address = Address.create({ address: user_addresses, user_id: current_user.id, is_active: true })
              else
                current_user.addresses.update_all(is_active: false)
                user_addresses = user_addresses.gsub(/\n    /, '')
                user_addresses = user_addresses.gsub(/\n/, '')
                user_addresses = user_addresses.gsub!(/[\[\]]/,'').split(/\s*,\s*/)
                user_addresses.each do |user_address|
                  create_address = Address.create({ address: user_address.gsub(/[^0-9A-Za-z]/, ''), user_id: current_user.id, is_active: true })
                end
              end
            end
          end
          resource.create_activity action: 'login', owner: resource
          resource.last_active = Time.now
          resource.save
          yield resource if block_given?
          respond_with resource, location: after_sign_in_path_for(resource)
        end
      else
        user = User.find_by_username(params[:user][:username])
        if user.present?
          file = File.exists? ("public/pgp/users/#{user.id}/key.txt")
          if file.eql? true
            redirect_to input_string_path(username: params[:user][:username])
          else
            set_flash_message :notice, "incorrect password and no public PGP stored for this user"
            redirect_to new_user_session_path
          end
        else
          set_flash_message :notice, "Sorry we can found that username"
          redirect_to new_user_session_path
        end
      end
    else
      sign_out @user
      redirect_to new_user_session_path, alert: "captcha is not valid"
    end
  end

  # DELETE /resource/sign_out
  def destroy
    string_indentifier = SecureRandom.hex
    current_user.string_indentifier = string_indentifier
    current_user.save
    current_user.create_activity action: 'logout', owner: current_user
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    yield if block_given?
    respond_to_on_destroy
  end

  protected

  def sign_in_params
    devise_parameter_sanitizer.sanitize(:sign_in)
  end

  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    { methods: methods, only: [:password] }
  end

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end

  private

  # Check if there is no signed in user before doing the sign out.
  #
  # If there is no signed in user, it will set the flash message and redirect
  # to the after_sign_out path.
  def verify_signed_out_user
    if all_signed_out?
      set_flash_message :notice, :already_signed_out if is_flashing_format?

      respond_to_on_destroy
    end
  end

  def all_signed_out?
    users = Devise.mappings.keys.map { |s| warden.user(scope: s, run_callbacks: false) }

    users.all?(&:blank?)
  end

  def respond_to_on_destroy
    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.all { head :no_content }
      format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name) }
    end
  end
end