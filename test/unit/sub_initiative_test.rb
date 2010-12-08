require 'test_helper'

class SubInitiativeTest < ActiveSupport::TestCase
  def setup
    @sub_initiative = SubInitiative.make
  end
  
  test "truth" do
    assert true
  end
end