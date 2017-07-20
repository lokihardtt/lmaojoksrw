class CreateDeposits < ActiveRecord::Migration
  def change
    create_table :deposits do |t|
      t.integer :user_id
      t.text :txid
      t.boolean :status, default: false

      t.timestamps
    end
  end
end
