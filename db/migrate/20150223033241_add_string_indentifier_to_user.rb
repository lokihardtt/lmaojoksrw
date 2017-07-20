class AddStringIndentifierToUser < ActiveRecord::Migration
  def change
    add_column :users, :string_indentifier, :string
  end
end
