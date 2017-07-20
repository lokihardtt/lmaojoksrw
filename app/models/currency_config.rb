class CurrencyConfig < ActiveRecord::Base

  def self.get_currency_with_status_true
    self.where(status: true).map(&:name)
  end

end