class AddTableCategoriesItems < ActiveRecord::Migration
  def change
    create_table :categories_items, id: false do |t|
      t.integer :category_id
      t.integer :item_id
    end

    add_index :categories_items, :category_id
    add_index :categories_items, :item_id
  end
end
