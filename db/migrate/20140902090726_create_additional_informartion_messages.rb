class CreateAdditionalInformartionMessages < ActiveRecord::Migration
  def change
    create_table :additional_informartion_messages do |t|
      t.text :message

      t.timestamps
    end
  end
end
