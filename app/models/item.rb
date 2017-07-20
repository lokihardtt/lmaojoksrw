class Item < ActiveRecord::Base
	is_impressionable
  include PublicActivity::Model
  tracked owner: ->(controller, model) { controller && controller.current_user }
	
  has_and_belongs_to_many :shipping_options
  has_and_belongs_to_many :categories
  has_and_belongs_to_many :countries
  belongs_to :country, foreign_key: :ship_from
  belongs_to :user
  has_many :galleries, dependent: :destroy
  has_many :orders, dependent: :destroy
  accepts_nested_attributes_for :galleries, :reject_if => :all_blank, :allow_destroy => true

  scope :qty_available, -> { where("quantity > 0") }

  validates :name, :price, :quantity, presence: true
  validates :price, numericality: { :greater_than_or_equal_to => 0.0001, message: "The price should be greater than 0.0001 BTC" }

  before_create :generate_random_string
  before_validation :check_currency_item_price

  attr_accessor :price_in_btc

  def self.get_uncategories_items
    self.joins('LEFT JOIN categories_items ON categories_items.item_id = items.id').where(categories_items: { category_id: nil })
  end

  def self.ship_from_item
    self.joins(:country, :user).where("users.role = ? AND items.quantity > 0", "Vendor").select("COUNT(items.*) as item_count, countries.name as country_name, countries.id as country_id").group('country_name, country_id').group_by { |group| [group.country_name, group.country_id ] }
  end

  def self.get_time
    current_time = Time.now.utc
    seventy_two_hours_ago = current_time - 72.hours
  end

  def self.get_filtered_items(params)
    country_ids = []
    seventy_two_hours_ago = self.get_time
    
    if params[:limit].present?
      limit = params[:limit]
    else
      limit = 20
    end

    if params[:hours].eql?"all"
      vendor_activity = "all"
    end

    if params[:sort].eql?"quantity"
      sort = "items.quantity desc"
    elsif params[:sort].eql?"newest"
      sort = "items.created_at desc"
    elsif params[:sort].eql?"rating"
      sort = "SUM(orders.rating) desc"
    elsif params[:sort].eql?"total_order"
      sort = "total_quantity desc"
    else
      sort = "items.id asc"
    end


    items = self.joins(:user)

    #country
    if params[:country].present? && !params[:country].zero?
      items = items.joins(:countries).where("countries_items.country_id IN (?)", params[:country])
    end

    #ship_to
    if params[:ship_to].present? || (params[:ship_to].present? && params[:ship_from].present?)
      country_ids << params[:ship_to].to_i
      country_ids << params[:ship_from].to_i if params[:ship_from].present?
      items = items.joins(:countries).where("countries_items.country_id IN (?)", country_ids)
    elsif params[:ship_from].present?
      # ship_from filter
      items = items.joins(:country).where(ship_from: params[:ship_from]) 
    end
    
    # Activity filter
    if vendor_activity.present? || params[:ship_to].present? || params[:ship_from].present?
      items = items.where(is_hidden: false)
    else
      items = items.where("users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE", seventy_two_hours_ago)
    end

    # Rating filter
    if params[:rating].present? || params[:sort].eql?("rating") || params[:sort].eql?("total_order")
      if params[:rating].eql?("0") || params[:rating].nil?
        items = items.joins("LEFT OUTER JOIN orders ON items.id = orders.item_id").select("coalesce(SUM(orders.quantity), 0) as total_quantity, items.*")
      else
        items = items.joins(:orders).select("SUM(orders.quantity) as total_quantity, items.*").having("SUM(orders.rating) >= ?", params[:rating])
      end
    end

    # Member filter
    if params[:member].eql?"member"
      items = items.where("users.member = ? AND items.is_hidden IS FALSE", "Confirmed")
    end

    #keyword filter
    if params[:name].present?
      items = items.where("users.username ILIKE ? OR items.name ILIKE ?", "%#{params[:name]}%", "%#{params[:name]}%")
    end

    # limit filter
    items.order("#{sort}").group("items.id")

    currencies = JSON.load(open("https://bitpay.com/api/rates"))
    active_currencies = CurrencyConfig.where(status: true).map(&:name)
    rates = {}
    currencies.each do |currency|
      if active_currencies.include? currency['code']
        rates[currency['code'].downcase.to_sym] = currency['rate']
      end
    end

    items.each do |item|
      if item.currency.present?
        if active_currencies.include? item.currency.upcase
          item.price_in_btc = item.price / rates[item.currency.downcase.to_sym]
        end
      else
        item.price_in_btc = item.price
      end
    end

    if params[:sort].eql?"lowest"
      items = items.sort_by { |item| item.price_in_btc } 
    elsif params[:sort].eql?"highest"
      items = items.sort_by { |item| item.price_in_btc }.reverse
    end

    items = Kaminari.paginate_array(items).page(params[:page]).per(limit)
  end

  def self.duplicate_item(params)
    item = self.find(params[:item_id])
    new_item = item.dup
    new_item.save
    item.galleries.each do |gallery|
      item_gallery = Gallery.new
      gallery_path = gallery.image.current_path
      if File.exist?(gallery_path)
        item_gallery.image = File.open(gallery_path)
      else
        gallery_url = gallery.image.url
        item_gallery.image = open(URI.parse(gallery_url))
      end
      item_gallery.item_id = new_item.id
      item_gallery.save
    end
    categories = item.categories
    countries = item.countries
    new_item.categories << categories
    new_item.countries << countries

    new_item
  end

  def self.change_status(params)
    item = self.find(params[:item_id])
    item.is_hidden = params[:item_status]
    item.save
  end

  def price_with_precision
    old_price = self.price.to_s
    new_price = BigDecimal.new(old_price)
    new_price
  end

  def converted_price(rate)
    price / rate
  end

  def generate_random_string
    self.random_string = SecureRandom.hex
  end

  def check_currency_item_price
    unless self.currency.eql?("BTC") || self.currency.eql?("Bitcoin")
      if self.currency.eql? "United States Dollar"
        self.currency = "USD"
      elsif currency.eql?"Indonesian Rupiah"
        self.currency = "IDR"
      end

      group_local = BitcoinCurrency.select { |bc| bc.code.eql? self.currency }
      new_price = self.price.to_f / group_local.first.rate.to_f
      
      self.errors.add(:price, "The price should be greater than 0.0001 BTC") if new_price <= 0.0001
    end
  end
end




