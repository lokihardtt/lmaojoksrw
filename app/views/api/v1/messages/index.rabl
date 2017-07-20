collection @conversations_users, root: :conversations_users
attributes :id, :created_at, :updated_at
node :sender_username do |conversations_user|
  conversations_user.last_recipient.username
end
node :last_message do |conversations_user|
  conversations_user.last_message.body
end
