class AddTxIdToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :tx_id, :text
  end
end
