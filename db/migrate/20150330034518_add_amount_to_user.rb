class AddAmountToUser < ActiveRecord::Migration
  def change
    add_column :users, :amount, :float, default: 0
  end
end
