class AddCoversationIdToPrivateMessage < ActiveRecord::Migration
  def change
    add_column :private_messages, :conversation_id, :integer
  end
end
