require 'test_helper'

class FundingSourceAllocationTest < ActiveSupport::TestCase
  def setup
    @funding_source_allocation = FundingSourceAllocation.make
  end
  
  test "truth" do
    assert true
  end
end