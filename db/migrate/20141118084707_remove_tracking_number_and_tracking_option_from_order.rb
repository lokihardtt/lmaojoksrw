class RemoveTrackingNumberAndTrackingOptionFromOrder < ActiveRecord::Migration
  def change
    remove_column :orders, :tracking_number
    remove_column :orders, :tracking_option
  end
end
