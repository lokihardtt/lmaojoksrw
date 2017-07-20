class AddWithdrawPassword < ActiveRecord::Migration
  def change
    add_column :users, :withdraw_password, :string
  end
end
