require 'gpgme'

class ConversationsController < ApplicationController
  before_filter :authenticate_user!
  before_action :category
  before_action :mailbox
  helper_method :mailbox, :conversation

  def create
    recipient_email = conversation_params(:recipient)
    recipient = User.where(username: recipient_email).first
    if conversation_params[:encrypted].eql?("1")
      email = nil
      key = `gpg --import "public/pgp/users/#{recipient.id}/publickey.asc" 2>&1`
      key.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) { |x| email = x }
      crypto = GPGME::Crypto.new(:armor => true, :always_trust => true)
      conversation_params[:body] = crypto.encrypt "#{conversation_params[:body]}", :recipients => "helmiakbar10@gmail.com"
      conversation_params[:body] = conversation_params[:body].read
    end

    if recipient.present?
      conversation = current_user.send_message(recipient, *conversation_params(:body, :subject)).conversation
      redirect_to inbox_conversations_url, notice: "Your message has been sent."
    else
      redirect_to :conversations, notice: "We are sorry we cannot find user with that username."
    end
  end

  def new
    @recipient = User.find(params[:user_id])
    @file = File.exists? ("public/pgp/users/#{@recipient.id}/key.txt")
  end

  def inbox
    @inbox = @mailbox.inbox
  end

  def sentbox
    @sentbox = @mailbox.sentbox
  end

  def trash_list
    @trash = @mailbox.trash
  end

  def reply
    current_user.reply_to_conversation(conversation, *message_params(:body, :subject))
    redirect_to conversation_path(conversation)
  end

  def trash
    conversation.move_to_trash(current_user)
    redirect_to :conversations
  end

  def untrash
    conversation.untrash(current_user)
    redirect_to :conversations
  end

  private

  def mailbox
    @mailbox ||= current_user.mailbox
  end

  def conversation
    @conversation ||= mailbox.conversations.find(params[:id])
  end

  def conversation_params(*keys)
    fetch_params(:conversation, *keys)
  end

  def message_params(*keys)
    fetch_params(:message, *keys)
  end

  def fetch_params(key, *subkeys)
    params[key].instance_eval do
      case subkeys.size
      when 0 then self
      when 1 then self[subkeys.first]
      else subkeys.map{|k| self[k] }
      end
    end
  end
end
