ActiveAdmin.register Order, as: "Order" do

  # config.paginate = false
  config.per_page = 50

  actions :all, :except => [:new, :edit, :show]

  controller do
    def index
      index! do |format|
        now = Time.now
        time = (now -14)
        @orders = ShoppingCart.joins(:orders).where("orders.status NOT IN (?) AND orders.updated_at < ?", "Not Pay", time).uniq.page(params[:page])
        # @orders = ShoppingCart.all.page(params[:page])
        # @orders = ShoppingCart.joins(:orders).where("orders.status = ?", "Pending").uniq.page(params[:page])
        format.html
      end
    end

    def destroy
      order = ShoppingCart.find(params[:id])
      order.orders.delete_all
      order.destroy
      redirect_to action: :index, notice: "Order already deleted"
    end
  end

  # index(:paginate => false) do
  index do
    column "<input id=\"collection_selection_toggle_all\" name=\"collection_selection_toggle_all\" class=\"toggle_all\" type=\"checkbox\">".html_safe do |order|
        check_box_tag "collection_selection[]", order.id, false, id: "batch_action_item_#{order.id}", class: 'collection-selection'
    end
    column :id
    column :user do |order|
      "#{order.user.username}"
    end
    column :status do |order|
    	"#{order.orders.first.status}"
    end
    actions
  end

  batch_action :destroy do |selection|
    orders = ShoppingCart.find(selection)
    orders.each do |order|
      order.orders.delete_all
      order.destroy
    end
    redirect_to action: :index, notice: "Success deleted selected order"
  end
end