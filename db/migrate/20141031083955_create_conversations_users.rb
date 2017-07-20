class CreateConversationsUsers < ActiveRecord::Migration
  def change
    create_table :conversations_users do |t|
      t.integer :conversation_id
      t.integer :sender_id
      t.integer :receiver_id
      t.boolean :is_deleted
      t.boolean :is_read

      t.timestamps
    end
  end
end
