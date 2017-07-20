class AddAdditionalInformationMessagesIdToShoppingCart < ActiveRecord::Migration
  def change
    add_column :shopping_carts, :additional_information_message_id, :integer
  end
end
