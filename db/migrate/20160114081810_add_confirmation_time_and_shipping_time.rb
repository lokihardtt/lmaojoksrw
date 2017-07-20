class AddConfirmationTimeAndShippingTime < ActiveRecord::Migration
  def change
    add_column :orders, :confirmation_time, :date
    add_column :orders, :shipping_time, :date
  end
end
