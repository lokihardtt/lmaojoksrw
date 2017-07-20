class AddQuantityAndCurrencyToItem < ActiveRecord::Migration
  def change
    add_column :items, :quantity, :integer
    add_column :items, :currency, :string
  end
end
