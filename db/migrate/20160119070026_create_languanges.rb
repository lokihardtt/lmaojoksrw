class CreateLanguanges < ActiveRecord::Migration
  def change
    create_table :languanges do |t|
      t.string :name
      t.boolean :status, default: false

      t.timestamps
    end
  end
end
