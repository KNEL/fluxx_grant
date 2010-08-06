require 'test_helper'

class ProgramTest < ActiveSupport::TestCase
  test "ability to validate a program" do
    prog = Program.create
    assert_equal 2, prog.errors.size
    prog = Program.create :name => 'Fun Program'
    assert_not_nil prog.id
  end
  
  test "ability to navigate to initiatives" do
    prog = Program.create :name => 'Fun Program'
    assert_equal 0, prog.initiatives.length
    initiative = Initiative.create :name => 'Fun Program', :program => prog
    prog.initiatives << initiative
    assert_equal 1, prog.initiatives.length
  end
end
