module PrivateMessagesHelper
  def create_conversation(conversation, recepient, sender)
    conversation_user = ConversationsUser.create({ conversation_id: conversation, sender_id: current_user.id, receiver_id: recepient, is_deleted: false, is_read: true })
  end

  def is_conversation_not_deleted?(conversation)
  	con = conversation.private_messages.last.conversation.conversations_users.where(conversation_id: conversation.id, receiver_id: current_user.id).first
  	con && con.is_deleted.eql?(false)
  	# private_message = conversation.private_messages.where(receiver_id: current_user.id).first
    # private_message && private_message.is_deleted.eql?(false)
  end

end
