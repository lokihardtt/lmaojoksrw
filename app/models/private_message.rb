class PrivateMessage < ActiveRecord::Base
  belongs_to :sender, class_name: "User", foreign_key: :sender_id
  belongs_to :receiver, class_name: "User", foreign_key: :receiver_id
  belongs_to :conversation

  validates :body, presence: true

  def self.send_message(current_user, receiver_id, params, user)
    check_sender_conversation = current_user.sender_conversations_users.first.sender_id rescue nil
    check_receiver_conversation = current_user.receiver_conversations_users.first.receiver_id rescue nil

    check_sender_conversation1 = user.sender_conversations_users.first.sender_id rescue nil
    check_receiver_conversation1 = user.receiver_conversations_users.first.receiver_id rescue nil
    
    if check_sender_conversation.present? && check_receiver_conversation1.present?
      conversation = ConversationsUser.where(sender_id: check_sender_conversation, receiver_id: check_receiver_conversation1)
      if conversation.present?
        conversation = conversation.first.conversation_id
      else
        conversation = Conversation.create
        conversation  = conversation.id
      end
    elsif check_sender_conversation1.present? && check_receiver_conversation.present?
      conversation = ConversationsUser.where(sender_id: check_sender_conversation1, receiver_id: check_receiver_conversation)
      conversation = conversation.first.conversation_id
    else
      conversation = Conversation.create
      conversation  = conversation.id
    end
    
    check_conversation = ConversationsUser.where( sender_id: current_user.id, receiver_id: receiver_id )
    if check_conversation.blank?
      conversation_user = ConversationsUser.create({ conversation_id: conversation, sender_id: current_user.id, receiver_id: receiver_id, is_deleted: false, is_read: false })
      conversation_user1 = ConversationsUser.create({ conversation_id: conversation, sender_id: receiver_id, receiver_id: current_user.id, is_deleted: false, is_read: true })
    else
      check_conversation = check_conversation.first
      check_conversation.is_read = false
      check_conversation.is_deleted = false
      check_conversation.save
    end

    check_conversation1 = ConversationsUser.where( sender_id: receiver_id, receiver_id: current_user.id ).first
    if check_conversation1.present?
      check_conversation1.is_deleted = false
      check_conversation1.is_read = true
      check_conversation1.save
    end

    if params[:encrypted].present?
      file = File.exists? ("public/pgp/users/#{receiver_id}/key.txt")
      if file.eql? true
        email = nil
        key = `gpg --import "public/pgp/users/#{receiver_id}/publickey.asc" 2>&1`
        key.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| email = x }
        crypto = GPGME::Crypto.new(:armor => true, :always_trust => true)
        params[:private_message][:body] = crypto.encrypt "#{params[:private_message][:body]}", :recipients => "helmiakbar10@gmail.com"
        params[:private_message][:body] = params[:private_message][:body].read
      end
    end

    private_message = self.create({ sender_id:  current_user.id, receiver_id: receiver_id, body: params[:private_message][:body], conversation_id: conversation })
    private_message.conversation.update_attributes(updated_at: Time.now)
  end
end
