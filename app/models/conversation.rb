class Conversation < ActiveRecord::Base
  has_many :private_messages
  has_many :conversations_users
  has_many :users, through: :conversations_users
  has_many :users_receivens, class_name: "User", through: :conversations_users
end
