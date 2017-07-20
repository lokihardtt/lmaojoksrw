class AddTxidToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :txid, :string
    add_column :transactions, :order_ids, :string
  end
end
