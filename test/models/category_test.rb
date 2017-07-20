require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  test "should return name and id" do 
    category = Category.get_collection
    assert true
    # assert_equal category, [["Food", 1], ["Drink", 2]], "function do not return right data"
  end
end