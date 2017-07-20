collection @user, root: :user
attributes :id, :username, :location, :currency, :last_sign_in_at, :created_at, :updated_at
node(:publickey) { @publickey }
node(:bitcoin_address) { @bitcoin_address }
node(:bitcoin_balance) { @bitcoin_balance }
