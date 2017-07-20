class ChangeDateFormatInInvitationUser < ActiveRecord::Migration
  def up
    change_column :invitation_users, :invitation_accepted_at, :datetime
  end

  def down
    change_column :invitation_users, :invitation_accepted_at, :date
  end
end
