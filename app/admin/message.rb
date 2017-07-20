ActiveAdmin.register PrivateMessage, as: "Message" do

  config.per_page = 50
  # config.paginate = false
  
  actions :all, :except => [:new, :edit, :show]

	# index(:paginate => false) do
  index do
		column "<input id=\"collection_selection_toggle_all\" name=\"collection_selection_toggle_all\" class=\"toggle_all\" type=\"checkbox\">".html_safe do |private_message|
        check_box_tag "collection_selection[]", private_message.id, false, id: "batch_action_item_#{private_message.id}", class: 'collection-selection'
    end
    column :id
    column :body
  end

  # batch_action :delete_all do |selection|
  # 	PrivateMessage.destroy_all
  #   redirect_to action: :index, notice: "Success deleted all Message"
  # end
  
end