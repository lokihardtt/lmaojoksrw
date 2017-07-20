class AddPhraseToUser < ActiveRecord::Migration
  def change
    add_column :users, :phrase, :text
  end
end
