class AddAutoCancelToApplicationConfiguration < ActiveRecord::Migration
  def change
    add_column :application_configurations, :auto_cancel, :integer
  end
end
