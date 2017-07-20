ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  page_action :withdraw_funds, method: :post do
    if current_admin_user.valid_password?(params[:password])
      tx_id = `bitcoin-cli sendfrom admin #{params[:bitcoin_address].gsub(/\n/, '')} #{params[:amount].to_f} 1 '{ from => "withdraw", to => #{current_admin_user.username}}' #{current_admin_user.username}`
      if tx_id.present?
        Transaction.create({ transaction_type: "Withdraw", status: "sent", amount: params[:amount].to_f, username: current_admin_user.username })
        msg = "Congratulation your withdraw success"
      else
        msg = "Sorry the transaction is failed. Please try again"
      end
    else
      msg = "Sorry your withdraw password not match. Please input the correct password"
    end
    
    redirect_to admin_dashboard_path, notice: msg
  end

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      h2 do
        span "Admin Balance"
        span `bitcoin-cli getbalance admin`.to_f.round(6)
        span "BTC Available"
      end
      h3 "Deposit Funds -"
      h4 do
        span "Send funds to the address"
        span `bitcoin-cli getaccountaddress admin` 
        span "to deposit funds"
      end
    end
    div do
      render partial: 'admin/dashboard/form_withdraw'
    end
  end
end
