collection @messages, root: :message
attributes :id, :body, :created_at
node :sender_username do |messages|
  messages.sender.username
end
node (:recipient_id) { @recipient.id }