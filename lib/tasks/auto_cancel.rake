namespace :auto_cancel do
  desc "TODO"
  task cancel: :environment do
    Order.auto_cancel_orders
  end
end
