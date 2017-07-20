class RenameLanguangesTable < ActiveRecord::Migration
  def self.up
    rename_table :languanges, :languages
  end

  def self.down
    rename_table :languages, :languanges
  end
end
