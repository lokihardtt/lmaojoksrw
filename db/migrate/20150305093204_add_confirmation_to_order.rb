class AddConfirmationToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :confirmation, :string
  end
end
