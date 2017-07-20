collection @category_items, root: :item
attributes :id, :name, :price, :created_at, :updated_at
child :galleries do |gallery|
  attributes :id, :image_url, :created_at, :updated_at
end