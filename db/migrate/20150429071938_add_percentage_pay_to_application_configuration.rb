class AddPercentagePayToApplicationConfiguration < ActiveRecord::Migration
  def change
    add_column :application_configurations, :percentage, :float
  end
end
