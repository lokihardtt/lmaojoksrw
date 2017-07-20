ActiveAdmin.register Language do
  menu :label => "Languages"

  filter :name
  actions :all, :except => [:new, :edit, :destroy]

  index do
    column :name
    column :status do |language|
     language.status ? "<span class=\"status_tag yes\">On</span>".html_safe: "<span class=\"status_tag no\">Off</span>".html_safe
    end
    actions defaults: true do |language|
      "#{link_to 'On', unhide_admin_language_path(language) if language.status.eql? false}
        #{link_to 'Off', hide_admin_language_path(language) if language.status.eql? true}".html_safe
    end
  end

  member_action :unhide, method: :get do
    language = Language.find(params[:id])
    language.status = true
    language.save
    redirect_to action: :index, notice: "Language has been turn on!"
  end

  member_action :hide, method: :get do
    language = Language.find(params[:id])
    language.status = false
    language.save
    redirect_to action: :index, notice: "Language has been turn off!"
  end

end