class Country < ActiveRecord::Base
  has_and_belongs_to_many :items

  def self.ship_to_item
    self.joins(:items => :user).select("countries.name, countries.id, COUNT(items.*) as item_count").where("users.role = ? AND items.quantity > 0", "Vendor").group("countries.name, countries.id").group_by { |group| [group.name, group.id] }
  end
end
