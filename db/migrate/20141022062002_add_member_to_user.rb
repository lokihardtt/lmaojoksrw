class AddMemberToUser < ActiveRecord::Migration
  def change
    add_column :users, :member, :string
  end
end
