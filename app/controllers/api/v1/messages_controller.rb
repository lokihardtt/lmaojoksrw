class Api::V1::MessagesController < ApiController
  skip_before_filter :verify_authenticity_token

  api :GET, '/v1/messages', 'Show all messages of user'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def index
    current_user = User.where(authentication_token: params[:auth_token]).first
    @conversations_users = current_user.receiver_conversations_users

    render "api/v1/messages/index"
  end

  api :GET, '/v1/list_recipient', 'Show all user for recipient message'
  param :auth_token, String, desc: "Authentication Token User", required: true
  def list_recipient
    current_user = User.where(authentication_token: params[:auth_token]).first
    @conversations_users = current_user.receiver_conversations_users
    if current_user.role.eql?"Vendor"
      @users = User.where("role = ? AND id NOT IN(?)", "Buyer", @conversations_users.map(&:sender_id))
    elsif current_user.role.eql?"Buyer"
      @users = User.where("role = ? AND id NOT IN(?)", "Vendor", @conversations_users.map(&:sender_id))
    end
    render "api/v1/messages/list_recipient"
  end

  api :GET, '/v1/create_message', 'Form for create a message'
  param :id, Integer, desc: "id of receiver", required: true
  def create_message
    @recieved = User.find(params[:id])
    if @recieved.present?
      email = nil
      key = `gpg --import "public/pgp/users/#{@recieved.id}/publickey.asc" 2>&1`
      @key = key.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| email = x }
    end
    render "api/v1/messages/create_message"
  end

  api :POST, '/v1/sent_message', 'Send a message'
  param :auth_token, String, desc: "Authentication Token User", required: true
  param :receiver_id, Integer, desc: "Recipient id, format of params must be 'params [:private_message] [:receiver_id]'."
  param :body, String, desc: "Content of message, format of params must be 'params [:private_message] [:body]'."
  def sent_message
    current_user = User.where(authentication_token: params[:auth_token]).first
    if params[:private_message][:body].present?
      if params[:private_message][:receiver_id].present?
        receiver_id = params[:private_message][:receiver_id]
        user = User.find(params[:private_message][:receiver_id])
      else
        user = User.where(username: params[:receiver_name]).first
        receiver_id = user.id
      end
      
      if params[:private_message][:receiver_id].present? || user.present?
        if current_user.role.eql? user.role
          render json: { status: "Sorry you cannot sent message to user with same role." }, status: :unprocessable_entity
        else
          private_message = PrivateMessage.send_message(current_user, receiver_id, params, user)

          render json: { status: "Your message has been sent." }, status: :success
        end
      else
        render json: { status: "Sorry we cann't find the username." }, status: :unprocessable_entity
      end
    else
      render json: { status: "Plase fill the message, Message cannot be blank." }, status: :unprocessable_entity
    end
  end

  api :POST, '/v1/reply', 'For reply a message and see all history of message'
  param :conversation_id, String, desc: "Id Conversations User", required: true
  param :user_id, Integer, desc: "Recipient id", required: true
  def reply
    conversation_user = ConversationsUser.find(params[:conversation_id])
    conversation_user.is_read = true
    conversation_user.save
    @recipient_id = params[:user_id]
    @messages = conversation_user.conversation.private_messages.order("created_at DESC")
    render "api/v1/messages/reply"
  end

  api :GET, '/v1/support_contact', 'For message to support contact'
  def support_contact
    @support = User.where(role: "Support").first
    render "api/v1/messages/support_contact"
  end

  def message_support_contact
    current_user = User.where(authentication_token: params[:auth_token]).first
    user = User.message_support_contact(current_user, params)
    render json: { status: "Your message has been sent." }, status: :success
  end
end