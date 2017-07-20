class AddStatusToInvitationUser < ActiveRecord::Migration
  def change
    add_column :invitation_users, :status, :boolean, default: true
  end
end
