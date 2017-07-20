collection @user, root: :user
attributes :id, :fe_policy, :description, :fee, :fa_pgp, :public_url, :phrase, :password,  :currency, :language, :withdraw_password, :created_at, :updated_at
child :addresses do |address|
  attributes :id, :address, :created_at, :updated_at
end
node(:publickey) { @publickey }