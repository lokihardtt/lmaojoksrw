collection @items, root: :items
attributes :id, :name, :price, :is_hidden, :quantity, :user_id, :created_at, :updated_at
child :galleries do |gallery|
  attributes :id, :image_url, :created_at, :updated_at
end
