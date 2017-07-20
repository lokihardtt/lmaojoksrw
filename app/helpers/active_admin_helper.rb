module ActiveAdminHelper
  def self.included(dsl)
    # nothing ...
  end

  def float_to_decimal(price)
    old_price = price.to_s
    new_price = BigDecimal.new(old_price)
    new_price.to_s
  end
end