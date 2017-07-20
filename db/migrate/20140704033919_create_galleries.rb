class CreateGalleries < ActiveRecord::Migration
  def change
    create_table :galleries do |t|
      t.text :image
      t.integer :item_id

      t.timestamps
    end
  end
end
