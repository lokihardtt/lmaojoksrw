class AddUnlimitedToItems < ActiveRecord::Migration
  def change
    add_column :items, :unlimited, :boolean, default: false
  end
end
