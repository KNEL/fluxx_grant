require 'test_helper'

class FipRequestTest < ActiveSupport::TestCase
  def setup
    @small_req = FipRequest.make :fip_title => 'hello there'
  end
  
end