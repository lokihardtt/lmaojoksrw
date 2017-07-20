class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :address
      t.integer :user_id
      t.boolean :is_active

      t.timestamps
    end
  end
end
