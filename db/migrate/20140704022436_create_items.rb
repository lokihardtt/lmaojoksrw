class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.text :description
      t.integer :price
      t.string :ship_from
      t.boolean :is_hidden
      t.boolean :is_up_front_payment
      # t.integer :category_id
      t.integer :user_id

      t.timestamps
    end
  end
end
