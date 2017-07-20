class Api::V1::CountriesController < ApiController
  skip_before_filter :authenticate_user_from_token!

  api :GET, '/v1/countries', 'Show all list country'
  def index
    @countries = Country.all
    render "api/v1/countries/index"
  end

  api :GET, '/v1/ship_from', 'Show all ship from country of items'
  def ship_from
    ship_from = Item.ship_from_item
    countries_item_count = { countries: [] }

    ship_from.each do |key, value|
      tmp_hash = {}
      tmp_hash[key.first.to_sym] = { country_id: key.second, item_count: value.map(&:item_count).sum }
      countries_item_count[:countries] << tmp_hash
    end
    render json: { countries: countries_item_count }
  end

  api :GET, '/v1/ship_to', 'Show all ship to country of items'
  def ship_to
    ship_to = Country.ship_to_item
    ship_to_countries = { countries: [] }

    ship_to.each do |key, value|
      tmp_hash = {}
      tmp_hash[key.first.to_sym] = { country_id: key.second, item_count: value.map(&:item_count).sum }
      ship_to_countries[:countries] << tmp_hash
    end
    render json: { countries: ship_to_countries }
  end
end