class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :transaction_type
      t.string :status
      t.float :amount
      t.string :username

      t.timestamps
    end
  end
end
