json.array!(@purchases) do |purchase|
  json.extract! purchase, :id, :user_id, :item_id, :status
  json.url purchase_url(purchase, format: :json)
end
