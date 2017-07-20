class RemoveWithdrawPasswordFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :withdraw_password
  end
end
