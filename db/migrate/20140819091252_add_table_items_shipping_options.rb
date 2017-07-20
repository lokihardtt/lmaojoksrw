class AddTableItemsShippingOptions < ActiveRecord::Migration
  def change
  	create_table :items_shipping_options, id: false do |t|
      t.integer :item_id
      t.integer :shipping_option_id
    end

    add_index :items_shipping_options, :item_id
    add_index :items_shipping_options, :shipping_option_id
  end
end
