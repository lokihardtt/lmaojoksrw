class AddMultiSigToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :multisig, :boolean, default: false
  end
end
