class BitcoinCurrency < ActiveRecord::Base
	def self.reset_currencies
    currencies = JSON.load(open("https://bitpay.com/api/rates"))
    BitcoinCurrency.delete_all
    BitcoinCurrency.create(currencies)
  end
end
