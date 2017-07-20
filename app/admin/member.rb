ActiveAdmin.register User, as: "Member" do

  actions :all, :except => [:new, :destroy, :edit, :show]
  filter :username
  filter :email
  filter :member

  permit_params :member

  scope_to do
    Class.new do
      def self.members
        User.where("role = ? AND member IS NOT NULL", "Vendor")
      end
    end
  end

  index do
    # selectable_column
    # column "<input id=\"collection_selection_toggle_all\" name=\"collection_selection_toggle_all\" class=\"toggle_all\" type=\"checkbox\">".html_safe do |member|
    #     check_box_tag "collection_selection[]", member.id, false, id: "batch_action_item_#{member.id}", class: 'collection-selection'
    # end
    column :username
    column :email
    column :member do |member|
      if member.member.eql?"Confirmed" 
        "<span class=\"member_tag yes\">Confirmed</span>".html_safe
      elsif member.member.eql?"Rejected"
        "<span class=\"member_tag no\">Rejected</span>".html_safe
      else
        "<span class=\"member_tag no\">Need Confirmation</span>".html_safe
      end
    end
    actions defaults: true do |member|
      unless member.member.eql? "Confirmed"
        "#{link_to 'Make Member', make_member_admin_member_path(member)}
        #{link_to 'Cancel and Refund', cancel_admin_member_path(member)}".html_safe
      end
    end
  end

  batch_action :accept do |selection|
    price = MemberPrice.first.price
    bitcoin_admin_address = `bitcoind getaccountaddress admin`.gsub(/\n/, '')
    users = User.where("id IN (?)", selection)
    users.update_all({member: "Confirmed"})
    users.each do |user|
      `bitcoind sendfrom escrow #{bitcoin_admin_address} #{price} 1 '{ "from" => #{user.username}, "to" => "admin", "amount" => #{price}}' "admin"`
    end
    redirect_to action: :index
  end

  batch_action :reject do |selection|
    price = MemberPrice.first.price
    users = User.where("id IN (?)", selection)
    users.update_all({member: "Rejected"})
    users.each do |user|
      bitcoin_user_address = `bitcoind getaccountaddress #{user.username}`.gsub(/\n/, '')
      tx_id = `bitcoind sendfrom escrow #{bitcoin_user_address} #{price} 1 '{ "from" => "escrow", "to" => "#{bitcoin_user_address}", "amount" => #{price}}' "admin"`
      if tx_id.present?
        Transaction.create({ transaction_type: "Reject Member", status: "receive", amount: price, username: user.username })
      end
    end
    redirect_to action: :index
  end

  member_action :make_member, method: :get do
    user = User.find(params[:id])
    user.member = "Confirmed"
    user.save
    price = MemberPrice.first.price
    bitcoin_admin_address = `bitcoind getaccountaddress admin`.gsub(/\n/, '')
    `bitcoind sendfrom escrow #{bitcoin_admin_address} #{price} 1 '{ "from" => #{user.username}, "to" => "admin", "amount" => #{price}}' "admin"`
    redirect_to action: :index
  end

  member_action :cancel, method: :get do
    user = User.find(params[:id])
    user.member = "Rejected"
    user.save
    price = MemberPrice.first.price
    bitcoin_user_address = `bitcoind getaccountaddress #{user.username}`.gsub(/\n/, '')
    tx_id = `bitcoind sendfrom escrow #{bitcoin_user_address} #{price} 1 '{ "from" => "escrow", "to" => "#{bitcoin_user_address}", "amount" => #{price}}' "admin"`
    if tx_id.present?
      Transaction.create({ transaction_type: "Reject Member", status: "sent", amount: price, username: user.username })
    end
    redirect_to action: :index
  end

end
