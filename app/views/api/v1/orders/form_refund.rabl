collection @order, root: :order
attributes :id, :total_payment
node(:buyer_address) { @buyer_address }