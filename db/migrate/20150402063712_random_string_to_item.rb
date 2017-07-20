class RandomStringToItem < ActiveRecord::Migration
  def change
    add_column :items, :random_string, :text
  end
end
