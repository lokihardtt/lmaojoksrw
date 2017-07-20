class Api::V1::CategoriesController < ApiController

  api :GET, '/v1/categories', 'Show all category'
  def index
    @categories = Category.all
    render 'api/v1/categories/index'
  end
end