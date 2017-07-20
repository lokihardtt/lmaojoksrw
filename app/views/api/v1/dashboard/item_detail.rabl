collection @item, root: :item
attributes :id, :name, :description, :price, :currency, :quantity
child :galleries do |gallery|
  attributes :id, :image_url, :created_at, :updated_at
end
child :user, object_root: false do
  attributes :id, :username
  node :shipping_options do |b|
    b.shipping_options.to_a.map { |shipping_option| { :id => shipping_option.id, :name => shipping_option.name, :price => shipping_option.price, :currency => shipping_option.currency } }
  end
end
child :country, object_root: false do
  attributes :name
end
node :countries do |a|
  a.countries.to_a.map { |countries| { :name => countries.name } }
end
child @related_items, object_root: false, root: :related_items do 
  attributes :id, :name
  child :galleries do |gallery|
    attributes :id, :image_url, :created_at, :updated_at
  end
end