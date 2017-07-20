class AddEscrowAddressToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :escrow_address, :text
  end
end
