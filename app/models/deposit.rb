class Deposit < ActiveRecord::Base
  belongs_to :user

  def self.update_amount
    deposit = self.where(status: false)
    doc = Nokogiri::HTML(open("https://blockchain.info/tx/#{deposit.txid}"))
    doc.css('.btn.btn-primary').each do |link|
      @confrim = link.content
    end
    
    if @confrim.present?
      if @confrim.gsub(/ Confirmations/, '').to_i >= 3
        deposit.status = true
        deposit.save
        user = deposit.user
        user.amount = `bitcoin-cli getbalance #{user.username}`
        user.save
      end
    end
  end

end