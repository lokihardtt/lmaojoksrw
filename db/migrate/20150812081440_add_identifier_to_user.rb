class AddIdentifierToUser < ActiveRecord::Migration
  def change
    add_column :users, :identifier, :text
  end
end
