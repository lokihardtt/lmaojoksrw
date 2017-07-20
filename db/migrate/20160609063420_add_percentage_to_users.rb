class AddPercentageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :percentage, :float, default: 1
  end
end
