class InvitedController < ApplicationController
  def check_token
    invited = InvitationUser.find_by_invitation_token(params[:token])
    if invited.present?
      if invited.status.eql?false
        redirect_to root_path, notice: "Your token already canceled by vendor"
      else
        if invited.role.eql?"Buyer"
          redirect_to new_user_registration_path
        else
          redirect_to vendor_sign_up_path
        end
      end
    else
      redirect_to root_path, notice: "We are sorry we cann't found your invitation token"
    end
  end
end