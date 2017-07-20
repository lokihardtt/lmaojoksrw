ActiveAdmin.register MemberPrice do
  include ActiveAdminHelper

  actions :all, :except => [:new, :destroy]
  filter :price
  filter :created_at
  filter :updated_at
  
  permit_params :price
  
  index do 
    column :id
    column :price do |member_price|
      float_to_decimal(member_price.price)
    end
    actions
  end
end
