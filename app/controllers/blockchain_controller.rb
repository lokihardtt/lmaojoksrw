class BlockchainController < ApplicationController
  before_action :category
  
  def new_wallet; end

  def create_new_wallet
    if params[:wallet_password] == current_user.pin
      if params[:wallet_password].size >= 10
        create_wallet = Blockchain::create_wallet("#{params[:wallet_password]}", 'bc3b42a4-9a58-4f3b-946a-4c3b53b863b1', label: "#{params[:wallet_label]}")
        current_user.identifier = create_wallet.identifier
        current_user.blockchain_password = params[:wallet_password]
        current_user.save

        create_address = Address.create({ address: create_wallet.address, user_id: current_user.id, is_active: true })

        if current_user.role.eql?"Vendor"
          redirect_to dashboard_vendor_path
        elsif current_user.role.eql?"Buyer"
          redirect_to dashboard_path
        end
      else
        redirect_to new_wallet_url, alert: "password must be greater than 10 characters"  
      end
    else
      redirect_to new_wallet_url, alert: "Your pin is not match"
    end
  end

end