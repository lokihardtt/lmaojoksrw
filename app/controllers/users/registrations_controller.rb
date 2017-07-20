require 'securerandom'
class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :require_no_authentication, only: [ :new, :create, :cancel, :vendor_sign_up ]
  prepend_before_filter :authenticate_scope!, only: [:edit, :update, :destroy]
  before_filter :category, only: [:edit, :update]
  before_filter :get_btc_rates

  # GET /resource/sign_up
  def new
    if params[:token].present?
      invited = InvitationUser.find_by_invitation_token(params[:token])
      if (invited.present?) && (invited.invitation_accepted_at.nil?) && (invited.status.eql?true)
        @countries = Country.all
        build_resource({})
        respond_with self.resource
      else
        redirect_to root_path, notice: "We are sorry we cann't found your invitation token or you token already invalid"
      end
    else
      @countries = Country.all.order("name ASC")
      build_resource({})
      respond_with self.resource
    end
  end

  # GET /resource/vendor_sign_up
  def vendor_sign_up
    @countries = Country.all.order("name ASC")
    build_resource({})
    respond_with self.resource
  end

  # POST /resource
  def create
    build_resource(sign_up_params)
    if simple_captcha_valid?
      resource.withdraw_password = resource.encrypted_password
      resource_saved = resource.save
      yield resource if block_given?
      if resource_saved
        resource.string_indentifier = SecureRandom.hex
        if resource.role.eql?"Vendor"
          shipping_option =  ShippingOption.create({ name: "Free", price: 0.0, currency: "USD", user_id: resource.id })
          resource.percentage = ApplicationConfiguration.where(name: "Percentage").first.percentage rescue 1
        end
        
        if params[:token].present?
          invite = InvitationUser.find_by_invitation_token(params[:token])
          invite.invitation_accepted_at = Time.now
          invite.save
          resource.role = invite.role
        end
        resource.save
        if @blockchain_payment_method.status.eql?true
          wallet = Blockchain::create_wallet("#{params[:user][:password]}", 'bc3b42a4-9a58-4f3b-946a-4c3b53b863b1')
          resource.identifier = wallet.identifier
          resource.save
        elsif @bitcoind_payment_method.status.eql?true
          user_address = `bitcoin-cli getaccountaddress #{resource.username}`
          if user_address.present?
            user_address = user_address.gsub(/\n/, '')
            create_address = Address.create({ address: user_address, user_id: resource.id, is_active: true })
          end
        end
        # create_address = Address.create({ address: wallet.address, user_id: resource.id, is_active: true })
        if resource.active_for_authentication?
          set_flash_message :notice, :signed_up if is_flashing_format?
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        @countries = Country.all
        clean_up_passwords resource
        respond_with resource
      end
    else
      @countries = Country.all
      set_flash_message :notice, "captcha_errors"
      render action: 'new'
    end

  end

  # GET /resource/edit
  def edit
    if current_user.string_indentifier.nil?
      @string_indentifier = SecureRandom.hex
    end
    @language = Language.where(status: true).map{ |language| [language.name, language.name.downcase] }
    @countries = Country.all.order("name ASC")
    @bitcoin_address = `bitcoin-cli getaccountaddress #{current_user.username}`.gsub(/\n/, '') rescue nil
    @bitcoin_balance = `bitcoin-cli getbalance #{current_user.username}` rescue nil
    @user_addresses = current_user.addresses
    @currency_true = CurrencyConfig.where(status: true).map{ |currency| [currency.name, currency.name] }
    check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{@user.id}/publickey.asc"].join
    if check_pgp.eql? true
      file = File.open("public/pgp/users/#{@user.id}/publickey.asc")
      publickey = file.read
      @publickey = publickey.gsub(/\r\n/, '<br/>')
    end
    render :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    if params[:user][:password] == params[:user][:password_confirmation]
      params[:user][:password] = params[:user][:password_confirmation] = params[:user][:current_password] if params[:user][:password].blank?
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
      
      if resource.valid_password?(params[:user][:current_password])
        params[:user][:pin] = params[:user][:new_pin]

        resource.create_activity action: 'update', owner: resource
        resource_updated = update_resource(resource, account_update_params)
        yield resource if block_given?
        if resource_updated
          if is_flashing_format?
            flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
              :update_needs_confirmation : :updated
            set_flash_message :notice, flash_key
          end

          sign_in resource_name, resource, bypass: true
          if params[:pgp_key].present?
            file = File.open("public/pgp/users/#{resource.id}/key.txt") rescue nil
            if file.blank? || !file.read.eql?(params[:pgp_key])
              info = PGP.upload_key(params[:pgp_key], current_user.id)
              redirect_to input_string_first_time_path
            else
              respond_with resource, location: after_update_path_for(resource)
            end
          else
            respond_with resource, location: after_update_path_for(resource)
          end
        else
          clean_up_passwords resource
          respond_with resource
        end
      else
        redirect_to edit_user_registration_url, notice: "Sorry your old password doesn't match. Please input the correct password for password"
      end
    else
      redirect_to edit_user_registration_url, notice: "Sorry your new login password or you new password is not match."
    end

  end

  # DELETE /resource
  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_flashing_format?
    yield resource if block_given?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end

  protected

  def update_needs_confirmation?(resource, previous)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous != resource.unconfirmed_email
  end

  # By default we want to require a password checks on update.
  # You can overwrite this method in your own RegistrationsController.
  def update_resource(resource, params)
    resource.update_with_password(params)
  end

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    self.resource = resource_class.new_with_session(hash || {}, session)
  end

  # Signs in a user on sign up. You can overwrite this method in your own
  # RegistrationsController.
  def sign_up(resource_name, resource)
    sign_in(resource_name, resource)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    if resource.is_a?(AdminUser)
      admin_dashboard_path
    else
      if resource.role.eql?"Vendor"
        upload_pgp_key_path
      else
        dashboard_path
      end
    end
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    scope = Devise::Mapping.find_scope!(resource)
    router_name = Devise.mappings[scope].router_name
    context = router_name ? send(router_name) : self
    context.respond_to?(:root_path) ? context.root_path : "/"
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    # signed_in_root_path(resource)
    if resource.role.eql?"Vendor"
      dashboard_vendor_url(locale: resource.locale)
    else
      dashboard_url(locale: resource.locale)
    end
  end

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", force: true)
    self.resource = send(:"current_#{resource_name}")
  end

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up)
  end

  def account_update_params
    devise_parameter_sanitizer.sanitize(:account_update)
  end
end