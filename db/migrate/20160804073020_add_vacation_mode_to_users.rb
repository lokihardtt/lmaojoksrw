class AddVacationModeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :vacation_mode, :boolean, default: false
  end
end
