collection @items, root: :items
attributes :id, :name, :price, :impressionist_count, :is_hidden, :created_at, :updated_at
child :galleries do |gallery|
  attributes :id, :image_url, :created_at, :updated_at
end