class User < ActiveRecord::Base
  include PublicActivity::Common
  acts_as_messageable
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :authentication_keys => [:username]
  has_many :items, dependent: :destroy
  has_many :invitation_users, dependent: :destroy
  has_many :shopping_carts, dependent: :destroy
  has_many :deposits, dependent: :destroy
  has_many :addresses, dependent: :destroy
  has_many :shipping_options, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :ordered_items, through: :items, source: :orders
  has_many :sender_tracking_numbers, class_name: "TrackingNumber", foreign_key: :sender_id
  has_many :receiver_tracking_numbers, class_name: "TrackingNumber", foreign_key: :receiver_id
  has_many :sender_messages, class_name: "PrivateMessage", foreign_key: :sender_id
  has_many :receiver_messages, class_name: "PrivateMessage", foreign_key: :receiver_id
  has_many :sender_conversations_users, class_name: "ConversationsUser", foreign_key: :sender_id
  has_many :receiver_conversations_users, class_name: "ConversationsUser", foreign_key: :receiver_id
  has_many :conversations, through: :sender_conversations_users
  has_many :receiver_conversations, source: :conversation, through: :receiver_conversations_users
  
  validates :username, uniqueness: true
  validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "only allows letters and numberic" }
  validates :username, length: { maximum: 20, too_long: "%{count} characters is the maximum allowed" }
  validates :username, :password, :location, :role, presence: true, if: :check_new_record
  validates :username, exclusion: { in: %w(admin escrow),
    message: "%{value} is reserved." }
  validates_confirmation_of :password, if: :check_new_record

  before_save :ensure_authentication_token

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def ensure_authentication_token!
    self.authentication_token = generate_authentication_token
    self.save!
  end

  def check_new_record
    self.new_record?
  end

  def update_with_password(params={}) 
    if params[:password].blank? 
      params.delete(:password) 
      params.delete(:password_confirmation) if params[:password_confirmation].blank? 
    end 
    update_attributes(params) 
  end

  def name
    email
  end

  def mailboxer_email(object)
    email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    username = conditions.delete(:username)
    where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => username.strip.downcase }]).first
  end

  def self.message_support_contact(current_user, params)
    user = self.where(role: "Support").first
    receiver_id = user.id
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

    check_conversation = ConversationsUser.where(sender_id: current_user.id, receiver_id: receiver_id )
    if check_conversation.blank?
      conversation_user = ConversationsUser.create({ conversation_id: conversation, sender_id: current_user.id, receiver_id: receiver_id, is_deleted: false, is_read: false })
    else
      check_conversation = check_conversation.first
      check_conversation.is_read = false
      check_conversation.save
    end

    private_message = PrivateMessage.create({ sender_id:  current_user.id, receiver_id: receiver_id, body: params[:message_support_contact][:body], conversation_id: conversation })
    
  end

  def get_pending_orders(page)
    pendings = self.ordered_items.joins(:shopping_cart).where(status: "Pending").order('created_at ASC').page(page)
  end

  def get_shipped_orders(page)
    shippeds = self.ordered_items.joins(:shopping_cart).where(status: "Shipped").order('created_at ASC').page(page)
    # shippeds = self.ordered_items.where(status: "Shipped").order('updated_at ASC')
  end

  def get_sent_orders(page)
    sents = self.ordered_items.joins(:shopping_cart).where(status: "Sent").order('created_at ASC').page(page)
    # sents = self.ordered_items.where(status: "Sent").order('updated_at ASC')
  end

  private

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
