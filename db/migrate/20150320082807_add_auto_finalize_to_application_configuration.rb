class AddAutoFinalizeToApplicationConfiguration < ActiveRecord::Migration
  def change
    add_column :application_configurations, :auto_finalize, :integer, default: 15
  end
end
