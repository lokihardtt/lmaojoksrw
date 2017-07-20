class AddFePolicyToUser < ActiveRecord::Migration
  def change
    add_column :users, :fe_policy, :string
    add_column :users, :description, :text
    add_column :users, :fee, :float
    add_column :users, :public_url, :string
  end
end
