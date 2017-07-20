object :orders

child @pendings, object_root: false, root: :pendings do 
  attributes :id, :quantity, :total_payment
  node :auto_cancel_date do |pending|
    distance_of_time_in_words(@four_day_ago, pending.updated_at)
  end
  child :item, object_root: false do 
    attributes :name, :ship_to
  end
  child :shipping_option, object_root: false do 
    attributes :name, :price, :currency
  end
end
child @shippeds, object_root: false, root: :shippeds do 
  attributes :id, :quantity, :total_payment, :additional_information_message
  child :item, object_root: false do 
    attributes :name, :ship_to
  end
  child :shipping_option, object_root: false do 
    attributes :name, :price, :currency
  end
end
child @sents, object_root: false, root: :sents do 
  attributes :id, :quantity, :total_payment
  child :item, object_root: false do 
    attributes :name, :ship_to
  end
  child :shipping_option, object_root: false do 
    attributes :name, :price, :currency
  end
end