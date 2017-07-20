class AddBlockChainPasswordToUser < ActiveRecord::Migration
  def change
    add_column :users, :blockchain_password, :string
  end
end
