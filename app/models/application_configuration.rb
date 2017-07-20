class ApplicationConfiguration < ActiveRecord::Base

  def self.get_invite_buyer_status
    self.where(name: "Invite Buyer").first.status
  end

  def self.get_invite_vendor_status
    self.where(name: "Invite Vendor").first.status
  end
  
end
