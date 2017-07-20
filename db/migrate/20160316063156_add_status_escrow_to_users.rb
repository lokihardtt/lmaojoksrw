class AddStatusEscrowToUsers < ActiveRecord::Migration
  def change
    add_column :users, :status_escrow, :boolean, default: true
  end
end
