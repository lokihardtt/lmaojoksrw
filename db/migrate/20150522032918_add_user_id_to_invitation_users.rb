class AddUserIdToInvitationUsers < ActiveRecord::Migration
  def change
    add_column :invitation_users, :user_id, :integer
  end
end
