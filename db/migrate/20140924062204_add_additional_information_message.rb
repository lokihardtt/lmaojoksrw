class AddAdditionalInformationMessage < ActiveRecord::Migration
  def change
    add_column :purchases, :additional_information_message, :text
  end
end
