ActiveAdmin.register InvitationUser, as: "Invite" do

  actions :all, :except => [:destroy, :edit, :show]

  permit_params :invitation_token, :role

  index do
    column "URL", :invitation_token do |token|
      if request.host === "www.openfreemarkettest.com"
        "https://#{request.host}/#{token.invitation_token}/register"
      else
        "#{request.protocol + request.host}/#{token.invitation_token}/register"
      end
    end
    column :role
    column "Invited By", :user_id do |user|
      user.user.username rescue "admin"
    end
    column :invitation_accepted_at
  end

  form do |f|
    f.inputs do
      f.input :invitation_token, input_html: { readonly: true, value: "#{SecureRandom.urlsafe_base64(30)}" }
      f.input :role, collection: ["Buyer", "Vendor"], include_blank: false
    end
    
    f.actions
  end

  controller do 
    def create
      @invite = InvitationUser.create({ invitation_token: params[:invitation_user][:invitation_token], role: params[:invitation_user][:role] })
      if @invite
        redirect_to admin_invites_path, notice: "Successfully generated code for invite"
      else
        redirect_to :back
      end
    end
  end
end