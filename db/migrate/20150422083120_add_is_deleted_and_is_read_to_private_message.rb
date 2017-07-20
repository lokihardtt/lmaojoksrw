class AddIsDeletedAndIsReadToPrivateMessage < ActiveRecord::Migration
  def change
    add_column :private_messages, :is_deleted, :boolean, default: false
    add_column :private_messages, :is_read, :boolean, default: false
  end
end
