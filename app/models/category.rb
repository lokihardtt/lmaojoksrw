class Category < ActiveRecord::Base
  has_and_belongs_to_many :items

  def self.get_collection
    self.pluck(:name, :id)
  end
end
