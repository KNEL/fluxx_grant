require 'test_helper'

class SubProgramTest < ActiveSupport::TestCase
  def setup
    @sub_program = SubProgram.make
  end
  
  test "truth" do
    assert true
  end
end