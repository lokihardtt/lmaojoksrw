class CreateCurrencyConfigs < ActiveRecord::Migration
  def change
    create_table :currency_configs do |t|
      t.string :name
      t.boolean :status

      t.timestamps
    end
  end
end
