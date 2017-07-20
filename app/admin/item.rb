ActiveAdmin.register Item do

include ActiveAdminHelper

  filter :name

  actions :all, :except => [:new, :edit, :destroy]
  permit_params :name, :description, :price, :ship_from, :is_hidden, :is_up_front_payment, 
    :quantity, :currency, :user_id, galleries_attributes: [:id, :image, :_done, :_destroy], shipping_option_ids: [], category_ids: []
  
  index do 
    column :name
    column :description
    column :price do |item|
      "#{float_to_decimal(item.price)} #{item.currency}"
    end
    column :quantity
    column :user_id do |item|
      item.user.username
    end
    actions
  end

  show do
    attributes_table do 
      row :name
      row :description
      row :quantity
      row "Price", :price do |item|
        "#{float_to_decimal(item.price)} #{item.currency}"
      end
      row 'Category' do |n|
        n.categories.map(&:name).join("<br />").html_safe
      end
      row "Ship Form", :ship_from do |i|
        i.country.name
      end
      row "Ship to" do |n|
        n.countries.map(&:name).join("<br />").html_safe
      end
      row "Shipping Options" do |n|
        n.shipping_options.map(&:name).join("<br />").html_safe
      end
      row :user_id
      row :random_string
    end
  end

  form do |f|
    f.inputs do
      f.input :user_id, input_html: { readonly: true } 
      f.input :name
      f.input :category_ids, as: :select, label: "Groups", collection: Category.get_collection, multiple: true 
      f.input :description
      f.input :price
      f.input :currency, as: :select, collection: ["BTC", "USD", "Euro"], include_blank: false
      f.input :is_up_front_payment, as: :select, collection: [["Sale price does not include fees", 0], ["Sale price includes fees", 1]], include_blank: false
      f.input :quantity
      f.input :is_hidden, collection: [["No", 0], ["Yes", 1]], include_blank: true, label: "Hidden"
      f.has_many :galleries do |gallery|
        gallery.input :image
      end
      f.input :ship_from, as: :country
    end 
    f.actions
  end
end