json.array!(@items) do |item|
  json.extract! item, :id, :name, :description, :price, :ship_from, :is_hidden, :is_up_front_payment
  json.url item_url(item, format: :json)
end
