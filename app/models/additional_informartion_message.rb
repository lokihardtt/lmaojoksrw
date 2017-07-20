class AdditionalInformartionMessage < ActiveRecord::Base
  has_many :shopping_carts, dependent: :destroy
end
