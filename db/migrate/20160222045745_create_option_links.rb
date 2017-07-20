class CreateOptionLinks < ActiveRecord::Migration
  def change
    create_table :option_links do |t|
      t.string :link
      t.boolean :disabled

      t.timestamps
    end
  end
end
