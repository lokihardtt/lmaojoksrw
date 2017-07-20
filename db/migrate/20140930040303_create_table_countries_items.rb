class CreateTableCountriesItems < ActiveRecord::Migration
  def change
    create_table :countries_items, id: false do |t|
      t.integer :country_id
      t.integer :item_id
    end

    add_index :countries_items, :country_id
    add_index :countries_items, :item_id
  end
end
