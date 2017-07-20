class ConversationsUser < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :sender, class_name: "User", foreign_key: :sender_id
  belongs_to :receiver, class_name: "User", foreign_key: :receiver_id

  def last_message
    self.conversation.private_messages.last
  end

  def last_recipient
    self.sender
  end

  def last_receiver
    self.receiver
  end

  def self.count_unread_message(current_user)
    self.where(receiver_id: current_user.id, is_read: false).count
  end
end
