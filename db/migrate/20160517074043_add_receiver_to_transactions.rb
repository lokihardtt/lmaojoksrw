class AddReceiverToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :receiver, :string
  end
end
