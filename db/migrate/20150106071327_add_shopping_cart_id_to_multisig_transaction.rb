class AddShoppingCartIdToMultisigTransaction < ActiveRecord::Migration
  def change
    add_column :multisig_transactions, :shopping_cart_id, :integer
    add_column :multisig_transactions, :order_id, :integer
    add_column :multisig_transactions, :tx_id, :text
    add_column :multisig_transactions, :total, :float
  end
end
