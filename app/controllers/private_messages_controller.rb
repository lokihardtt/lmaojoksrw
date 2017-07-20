class PrivateMessagesController < InheritedResources::Base
  skip_before_action :market_name, only: [:reply]
  before_filter :authenticate_user!
  before_action :category
  before_action :fetch_conversation_user, only: [:read_conversation, :unread_conversation, :trash]
  before_action :fetch_private_message, only: [:trash_private_message, :untrash_private_message, :unread_private_message, :read_private_message]

  def show_sender_detail
    @sender = User.find(params[:user_id])
    check_pgp = File.exist? [Rails.root, "/public/pgp/users/#{@sender.id}/publickey.asc"].join
    if check_pgp.eql? true
      file = File.open("public/pgp/users/#{@sender.id}/publickey.asc")
      publickey = file.read
      @publickey = publickey.gsub(/\r\n/, '<br/>')
    end
  end

  def support_contact
    @support = User.where(role: "Support").first
    @private_message = PrivateMessage.new
  end

  def message_support_contact
    user = User.message_support_contact(current_user, params)
    
    redirect_to private_messages_path, notice: "Your message has been sent"
  end

  def index
    @private_message = PrivateMessage.new
    @conversations = current_user.receiver_conversations.order("updated_at DESC")
    if @conversations.empty?
      @conversations = current_user.conversations.order("updated_at DESC")
    end
  end

  def reply
    @user = User.where(username: params[:user]).first
    conversation_user = ConversationsUser.where("sender_id = ? AND receiver_id = ?", @user.id, current_user.id ).first
    conversation_user_1 = ConversationsUser.where("sender_id = ? AND receiver_id = ?", current_user.id, @user.id ).first
    if conversation_user.present?
      conversation_user.update_attributes(is_read: true)
      @private_message = PrivateMessage.new
      @recipient_id = @user.id
      @messages = conversation_user.conversation.private_messages.where(is_deleted: false).order("created_at DESC")
    elsif conversation_user_1.present?
      conversation_user.update_attributes(is_read: true)
      @private_message = PrivateMessage.new
      @recipient_id = @user.id
      @messages = conversation_user_1.conversation.private_messages.where(is_deleted: false).order("created_at DESC")
    else
      redirect_to private_messages_path, notice: "Sorry you can open that url"
    end
    
    market_name
  end

  def trash
    @conversation_user.destroy
    redirect_to private_messages_path
  end

  def read_conversation
    @conversation_user.update_attributes(is_read: true)    
    redirect_to private_messages_path
  end

  def unread_conversation
    @conversation_user.update_attributes(is_read: false)    
    redirect_to private_messages_path
  end

  def trash_private_message
    @private_message.destroy
    redirect_to private_messages_path
  end

  def untrash_private_message
    @private_message.update_attributes(is_deleted: false)
    redirect_to private_messages_path
  end

  def read_private_message
    @private_message.update_attributes(is_read: true)
    redirect_to private_messages_path
  end

  def unread_private_message
    @private_message.update_attributes(is_read: false)
    redirect_to private_messages_path
  end

  def untrash
    messages = PrivateMessage.where("(sender_id = :sender_id AND receiver_id = :receiver_id) OR (sender_id = :receiver_id AND receiver_id = :sender_id)", { sender_id: params[:sender_id], receiver_id: current_user.id})
    messages.update_all(status: "Sent")
    if inbox.present?
      if inbox.include? current_user.id
        @senders = User.find([inbox])
      end
    end
    redirect_to private_messages_path
  end

  def new
    @recieved = User.find(params[:receiver_id])
    @file = File.exists? ("public/pgp/users/#{@recieved.id}/key.txt")
    @private_message = PrivateMessage.new
  end

  def show_pgp
    @private_message = PrivateMessage.new
    @recieved = User.find(params[:id])
    if @recieved.present?
      email = nil
      key = `gpg --import "public/pgp/users/#{@recieved.id}/publickey.asc" 2>&1`
      @key = key.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| email = x }
    end
  end

  def create
    if params[:private_message][:body].present?
      params[:private_message][:body] = params[:private_message][:body].gsub(/\n/, '<br/>')
      
      if params[:private_message][:receiver_id].present?
        receiver_id = params[:private_message][:receiver_id]
        user = User.find(params[:private_message][:receiver_id])
      else
        user = User.where(username: params[:receiver_name]).first
        receiver_id = user.id
      end
      
      if params[:private_message][:receiver_id].present? || user.present?
        if current_user.role.eql? user.role
          redirect_to private_messages_path, alert: "Sorry you cannot sent message to user with same role."
        else
          private_message = PrivateMessage.send_message(current_user, receiver_id, params, user)

          redirect_to private_messages_path, notice: "Your message has been sent"
        end
      else
        redirect_to private_messages_path, alert: "Sorry we can't find the username"
      end
    else
      redirect_to private_messages_path, alert: "Plase fill the message, Message cannot be blank"
    end
  end
  
  private

    def fetch_conversation_user
      @conversation_user = ConversationsUser.find(params[:conversations_user_id])
    end

    def fetch_private_message
      @private_message = PrivateMessage.find(params[:id])
    end

end





