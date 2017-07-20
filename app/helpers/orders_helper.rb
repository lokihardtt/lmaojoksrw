require 'nokogiri'
require 'open-uri'

module OrdersHelper
  def float_to_decimal(price)
    old_price = price.to_s
    new_price = BigDecimal.new(old_price)
    new_price.to_s
  end

  def update_order(id)
    order = Order.find(id)
    doc = Nokogiri::HTML(open("https://blockchain.info/address/#{order.escrow_address}"))
    doc.css('.btn .btn-danger').each do |link|
      @unconfrim = link.content
    end
    if @unconfrim.nil?
      doc.css('.btn.btn-primary').each do |link|
        @confrim = link.content
      end
      @confrim = @confrim.gsub(/ Confirmations/, '').to_i rescue 0

      unless @confrim >= 3
        order.status = "Pending"
        order.save
      end
    end
  end

  def status_btc(address)
    doc = Nokogiri::HTML(open("https://blockchain.info/address/#{address}"))
    doc.css('.btn .btn-danger').each do |link|
      @unconfrim = link.content
    end

    if @unconfrim.nil?
      doc.css('.btn.btn-primary').each do |link|
        @confrim = link.content
      end

      if @confrim.nil?
        doc.css('.btn.btn-success').each do |link|
          @success = link.content
        end
          @success
      else
        @confrim
      end

    else
      @unconfrim  
    end
  end

  def check_btc(address)
    doc = Nokogiri::HTML(open("https://blockchain.info/address/#{address}"))
    doc.css('.btn .btn-danger').each do |link|
      @unconfrim = link.content
    end
  end

  def status_btc_tx_id(tx_id)
    doc = Nokogiri::HTML(open("https://blockchain.info/tx/#{tx_id}"))
    doc.css('.btn .btn-danger').each do |link|
      @unconfrim = link.content
    end

    if @unconfrim.nil?
      doc.css('.btn.btn-primary').each do |link|
        @confrim = link.content
      end

      if @confrim.nil?
        doc.css('.btn.btn-success').each do |link|
          @success = link.content
        end
          @success
      else
        @confrim
      end

    else
      @unconfrim  
    end
  end

  def total(pending)
    total = pending.quantity + pending.item.price
  end

  def get_shipping_information(order)
    if order.present? && order.shopping_cart.additional_informartion_message.present?
      order.shopping_cart.additional_informartion_message.message.gsub(/\n/, '<br/>')
    end
  end
end
