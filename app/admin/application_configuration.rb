ActiveAdmin.register ApplicationConfiguration do
  actions :all, :except => [:destroy, :show, :new]

  permit_params :name, :status, :auto_finalize, :percentage, :auto_cancel

  form do |f|
    f.inputs do
      f.input :name, input_html: { readonly: true }
      if f.object.name.eql?"Finalize"
        f.input :auto_finalize
      end
      if f.object.name.eql?"Percentage"
        f.input :percentage
      end
      if f.object.name.eql?"Auto Cancel"
        f.input :auto_cancel
      end
    end
    
    f.actions
  end

  index do
    column :id
    column :name
    column :status do |status|
     status.status ? "<span class=\"status_tag yes\">On</span>".html_safe: "<span class=\"status_tag no\">Off</span>".html_safe
    end
    actions defaults: false do |status|
      "#{ link_to 'Edit', edit_admin_application_configuration_path(status) if (status.name.eql?('Finalize') || status.name.eql?('Percentage') || status.name.eql?('Auto Cancel')) }
      #{ link_to 'On', unhide_admin_application_configuration_path(status) if status.status.eql? false && ( !status.name.eql?('Finalize') && !status.name.eql?('Percentage') && !status.name.eql?('Auto Cancel')) }
      #{ link_to 'Off', hide_admin_application_configuration_path(status) if status.status.eql? true && ( !status.name.eql?('Finalize') && !status.name.eql?('Percentage') && !status.name.eql?('Auto Cancel')) }".html_safe
    end
  end

  batch_action :turn_off do |selection|
    ApplicationConfiguration.where("id IN (?) AND status = ?", selection, true).update_all({status: false})
    redirect_to action: :index, notice: "selected configuration has been turn off!"
  end

  batch_action :turn_on do |selection|
    ApplicationConfiguration.where("id IN (?) AND status = ?", selection, false).update_all({status: true})
    redirect_to action: :index, notice: "Selected configuration has been turn on!"
  end

  member_action :unhide, method: :get do
    configuration = ApplicationConfiguration.find(params[:id])
    configuration.status = true
    if configuration.name.eql?"bitcoind"
      blockchain_method = ApplicationConfiguration.find_by_name("Blockchain")
      blockchain_method.status = false
      blockchain_method.save
    elsif configuration.name.eql?"Blockchain"
      bitcoind_method = ApplicationConfiguration.find_by_name("bitcoind")
      bitcoind_method.status = false
      bitcoind_method.save
    end
    configuration.save
    redirect_to action: :index, notice: "configuration has been turn on!"
  end

  member_action :hide, method: :get do
    configuration = ApplicationConfiguration.find(params[:id])
    configuration.status = false
    if configuration.name.eql?"bitcoind"
      blockchain_method = ApplicationConfiguration.find_by_name("Blockchain")
      blockchain_method.status = true
      blockchain_method.save
    elsif configuration.name.eql?"Blockchain"
      bitcoind_method = ApplicationConfiguration.find_by_name("bitcoind")
      bitcoind_method.status = true
      bitcoind_method.save
    end
    configuration.save
    redirect_to action: :index, notice: "configuration has been turn off!"
  end

end