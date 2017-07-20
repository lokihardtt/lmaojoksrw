collection @shopping_cart, root: :shopping_cart
attributes :id
child :additional_informartion_message, object_root: false do
  attributes :id, :message
end
child :shopping_cart_items do
  attributes :id, :quantity, :price
  child :item do
    attributes :name
    child :user do
      attributes :username
      child :shipping_options do
        attributes :id, :name
      end
    end
  end
end
node (:bitcoin_balance) { @bitcoin_balance }