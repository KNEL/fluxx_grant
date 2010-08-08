require 'test_helper'

class ProgramTest < ActiveSupport::TestCase
  def setup
    @program = Program.make
  end
  
  test "test creating program" do
    assert @program.id
  end
end