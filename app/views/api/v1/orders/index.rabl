object :orders

child @not_orders, object_root: false, root: :not_orders do 
  attributes :id, :total_payment
  node :auto_cancel_date do |not_pay|
    distance_of_time_in_words(@four_day_ago, not_pay.updated_at)
  end
  child :item, object_root: false do 
    attributes :name, :ship_to
    child :user, object_root: false do
      attributes :username
    end
  end
end
child @pending_orders, object_root: false, root: :pending_orders do 
  attributes :id, :quantity, :total_payment, :additional_information_message
  child :item, object_root: false do 
    attributes :name, :ship_to
  end
  child :shipping_option, object_root: false do 
    attributes :name, :price, :currency
  end
end
child @shipped_orders, object_root: false, root: :shipped_orders do 
  attributes :id, :total_payment
  node :auto_cancel_date do |shipped|
    distance_of_time_in_words(@four_day_ago, shipped.updated_at)
  end
  child :item, object_root: false do 
    attributes :name, :ship_to
    child :user, object_root: false do
      attributes :username
    end
  end
end
child @sent_orders, object_root: false, root: :sent_orders do 
  attributes :id, :quantity, :total_payment
  child :item, object_root: false do 
    attributes :name, :ship_to
    child :user, object_root: false do
      attributes :username
    end
  end
  child :shipping_option, object_root: false do 
    attributes :name, :price, :currency
  end
end