ActiveAdmin.register MarketName do

  actions :all, :except => [:new, :destroy]
  
  filter :name

  permit_params :name

  show do
    attributes_table do
      row :name
    end
  end
  
  index do
    id_column
    column :name
    actions
  end
end
