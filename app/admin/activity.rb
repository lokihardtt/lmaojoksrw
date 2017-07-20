ActiveAdmin.register Activity do

  actions :all, :except => [:new, :edit, :destroy, :show]

  
end
