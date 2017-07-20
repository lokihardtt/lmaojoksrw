class Gallery < ActiveRecord::Base
  mount_uploader :image, ImageUploader
  belongs_to :item
end
