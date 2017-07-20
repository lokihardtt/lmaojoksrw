class CreateTrackingNumbers < ActiveRecord::Migration
  def change
    create_table :tracking_numbers do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.integer :order_id
      t.text :tracking_number

      t.timestamps
    end
  end
end
