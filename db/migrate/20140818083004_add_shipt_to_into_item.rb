class AddShiptToIntoItem < ActiveRecord::Migration
  def change
    add_column :items, :ship_to, :string
  end
end
