class CreateApplicationConfigurations < ActiveRecord::Migration
  def change
    create_table :application_configurations do |t|
      t.string :name
      t.boolean :status, default: false
      
      t.timestamps
    end
  end
end
