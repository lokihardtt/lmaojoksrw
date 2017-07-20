class InvitesController < ApplicationController
  before_action :authenticate_user!
  before_action :configuration_invite
  before_action :category
  
  def invite_new_buyer
    @invites = InvitationUser.where(user_id: current_user.id).order("created_at DESC")
  end

  def cancel_invited
    invite = InvitationUser.find(params[:id])
    invite.status = false
    invite.save
    redirect_to invite_new_buyer_path, notice: "Invite code has been canceled"
  end

  def sent_invitation
    invite = InvitationUser.create({ invitation_token: params[:invitation_token], role: params[:role], user_id: params[:user_id] })
    if invite
      redirect_to invite_new_buyer_path, notice: "Successfully generated code for invite"
    else
      redirect_to invite_new_buyer_path, notice: "Failed generated code for invite"
    end
  end

end