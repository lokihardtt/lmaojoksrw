json.array!(@addresses) do |address|
  json.extract! address, :id, :address, :user_id, :is_active
  json.url address_url(address, format: :json)
end
