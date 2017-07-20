ActiveAdmin.register Category do

  filter :name

  controller do
    def index
      index! do |format|
        @categories = Category.all.order("id ASC").page(params[:page])
        format.html
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
    end
  end

  permit_params :name

  index do
    id_column
    column :name
    actions
  end
end
