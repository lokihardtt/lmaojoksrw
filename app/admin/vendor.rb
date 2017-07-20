ActiveAdmin.register User, as: "Vendor" do

  filter :username
  filter :sign_in_count
  
  actions :all, :except => [:new, :destroy, :show]
  permit_params :percentage

  controller do
    def index
      index! do |format|
        @vendors = User.where("role = ?", "Vendor").order("created_at ASC").page(params[:page])
        format.html
      end
    end
  end

  index do
    column :username
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    column :status_escrow
    column :percentage
    actions do |vendor|
      "#{ link_to 'Enable escrow', enable_status_escrow_admin_vendor_path(vendor) unless vendor.status_escrow }
       #{ link_to 'Disable escrow', disable_status_escrow_admin_vendor_path(vendor) if vendor.status_escrow }".html_safe
    end
  end

  form do |f|
    f.inputs do
      f.input :percentage
    end  
    f.actions
  end

  member_action :enable_status_escrow, method: :get do
    resource.update_attributes(status_escrow: true)

    redirect_to admin_vendors_url, notice: "escrow for #{resource.username} has been enabled!"
  end
  
  member_action :disable_status_escrow, method: :get do
    resource.update_attributes(status_escrow: false)

    redirect_to admin_vendors_url, notice: "escrow for #{resource.username} has been disabled!"
  end
end
