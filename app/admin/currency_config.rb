ActiveAdmin.register CurrencyConfig do
  menu :label => "Currencies"
  actions :all, :except => [:new, :destroy, :show, :edit]

  controller do
    def index
      index! do |format|
        @currency_configs = CurrencyConfig.all.order("name ASC").page(params[:page])
        format.html
      end
    end
  end

  index do
    # column "<input id=\"collection_selection_toggle_all\" name=\"collection_selection_toggle_all\" class=\"toggle_all\" type=\"checkbox\">".html_safe do |currency_config|
    #   unless currency_config.name.downcase.eql? "btc"
    #     check_box_tag "collection_selection[]", currency_config.id, false, id: "batch_action_item_#{currency_config.id}", class: 'collection-selection'
    #   end
    # end
    # column :id
    column :name
    column :status do |currency_config|
     currency_config.status ? "<span class=\"status_tag yes\">On</span>".html_safe: "<span class=\"status_tag no\">Off</span>".html_safe
    end
    actions defaults: true do |currency_config|
      unless currency_config.name.downcase.eql? "btc"
        "#{link_to 'On', unhide_admin_currency_config_path(currency_config) if currency_config.status.eql? false}
        #{link_to 'Off', hide_admin_currency_config_path(currency_config) if currency_config.status.eql? true}".html_safe
      end
    end
  end

  batch_action :turn_off do |selection|
    CurrencyConfig.where("id IN (?) AND status = ?", selection, true).update_all({status: false})
    redirect_to action: :index, notice: "selected currency has been turn off!"
  end

  batch_action :turn_on do |selection|
    CurrencyConfig.where("id IN (?) AND status = ?", selection, false).update_all({status: true})
    redirect_to action: :index, notice: "Selected currency has been turn on!"
  end

  member_action :unhide, method: :get do
    currency = CurrencyConfig.find(params[:id])
    currency.status = true
    currency.save
    redirect_to action: :index, notice: "Currency has been turn on!"
  end

  member_action :hide, method: :get do
    currency = CurrencyConfig.find(params[:id])
    currency.status = false
    currency.save
    redirect_to action: :index, notice: "Currency has been turn off!"
  end

end
