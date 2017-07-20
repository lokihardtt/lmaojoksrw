ActiveAdmin.register User do

  filter :username
  filter :sign_in_count
  
  actions :all, :except => [:new, :edit]
  permit_params :email, :username, :role, :pin, :location, :currency, :password, :password_confirmation

  controller do
    def index
      index! do |format|
        @users = User.where("role != ?", "Support").order("created_at ASC").page(params[:page])
        format.html
      end
    end
  end

  index do
    column :username
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    actions
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :username
      f.input :pin
      f.input :role, collection: ["Buyer", "Vendor"]
      f.input :location, collection: Country.all.order("name ASC").collect{ |country| ["#{country.name}", country.id]}, include_blank: false
      f.input :currency, collection: ["Bitcoin", "United States Dollar", "British Pound Sterling", "Euro"], include_blank: false
      f.input :password
      f.input :password_confirmation
    end  
    f.actions
  end
end
