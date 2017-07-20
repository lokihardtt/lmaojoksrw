collection @new_item, root: :item
attributes :id, :name, :price, :description, :quantity, :is_hidden, :ship_from, :is_hidden, :created_at, :updated_at
child :galleries do |gallery|
  attributes :id, :image_url, :created_at, :updated_at
end
node :categories do |a|
  a.categories.to_a.map { |category| { :name => category.name } }
end
node :shipping_options do |b|
  b.shipping_options.to_a.map { |shipping_option| { :name => shipping_option.name } }
end
node :countries do |c|
  c.countries.to_a.map { |country| { :name => country.name } }
end