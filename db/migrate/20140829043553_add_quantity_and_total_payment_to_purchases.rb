class AddQuantityAndTotalPaymentToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :quantity, :integer
    add_column :purchases, :total_payment, :float
  end
end
