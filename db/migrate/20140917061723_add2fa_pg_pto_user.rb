class Add2faPgPtoUser < ActiveRecord::Migration
  def change
    add_column :users, :fa_pgp, :boolean
  end
end
