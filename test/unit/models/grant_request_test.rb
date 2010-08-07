require 'test_helper'

class GrantRequestTest < ActiveSupport::TestCase
  def setup
    @req = GrantRequest.make
  end
  
  test "create a request and check the amount_requested filter" do
    r = Request.new :amount_requested => "$200,000"
    assert_equal 200000, r.amount_requested
  end
  
  test "create a request and check the amount_recommended filter" do
    r = Request.new :amount_recommended => "$200,000"
    assert_equal 200000, r.amount_recommended
  end
  
end