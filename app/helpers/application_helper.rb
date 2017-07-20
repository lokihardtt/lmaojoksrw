module ApplicationHelper
  def convert_to_btc(currency, price)
    if (currency.eql?"Bitcoin") || (currency.eql?"BTC")
      @local_currency = price.to_f
    else
      if currency.eql?"United States Dollar"
        currency = "USD"
      elsif currency.eql?"Indonesian Rupiah"
        currency = "IDR"
      end
      group_local = @rates.select { |element_hash| element_hash["code"].eql?"#{currency}" }
      @local_currency = price.to_f / group_local.first['rate'].to_f
    end
    
    @local_currency.to_f.round(6)
  end

  def total_payment(key)
    cart = ShoppingCart.find(key)
    total_payment = cart.orders.map(&:total_payment).sum
  end

  def rating(id)
    ratings = Order.joins(:item).where("items.user_id = ?", id).map(&:rating)
    rating_average = ratings.inject{ |sum, el| sum + el }.to_f / ratings.size
    if (rating_average.eql? 0.0) || (rating_average.to_s.eql?"NaN")
      rating = "5.0/5.0"
    else
      rating = "(#{rating_average.round(2)}/#{ratings.size})"
    end
  end

  def order_size(id)
    ratings = Order.where(status: "Finalize").joins(:item).where("items.user_id = ?", id).count
  end

  def count_items_by_category(id, hours)
    current_time = Time.now.utc
    seventy_two_hours_ago = current_time - 72.hours
    category = Category.find(id)
    category_items = category.items.joins(:countries, :user)
    country_id = current_user.location.to_i

    if country_id.zero?
      category_items = category_items.where("items.quantity > 0 AND users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE ", 
        seventy_two_hours_ago).count   
    else
      category_items = category_items.where("items.quantity > 0 AND users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE AND countries.id = ?", 
        seventy_two_hours_ago, country_id).count   
    end
  end

  def count_item_in_uncategories(hours)
    current_time = Time.now.utc
    seventy_two_hours_ago = current_time - 72.hours
    uncategories_items = Item.joins('LEFT JOIN categories_items ON categories_items.item_id = items.id').where(categories_items: { category_id: nil })
    uncategories_items = uncategories_items.joins(:countries, :user)
    country_id = current_user.location.to_i

    if country_id.zero?
      @uncategories_items = uncategories_items.where("users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE ", 
        seventy_two_hours_ago).count  
    else
      @uncategories_items = uncategories_items.where("users.last_active >= ? AND users.vacation_mode IS FALSE AND items.is_hidden IS FALSE AND countries.id = ?", 
        seventy_two_hours_ago, country_id).count
    end
  end

  def show_image(image)
    image_item = File.open("public/#{image}") rescue nil
    if image_item
      image
    else
      'no_image_w_large.gif'
    end
  end

end
