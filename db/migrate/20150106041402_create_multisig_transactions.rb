class CreateMultisigTransactions < ActiveRecord::Migration
  def change
    create_table :multisig_transactions do |t|
      t.text :address
      t.text :redeem_script
      t.text :vendor_address
      t.text :buyer_address
      t.text :escrow_address

      t.timestamps
    end
  end
end
