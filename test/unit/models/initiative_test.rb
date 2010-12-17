require 'test_helper'

class InitiativeTest < ActiveSupport::TestCase
  test "ability to validate an initiative" do
    prog = Program.create :name => 'Fun Program'
    sub_prog = SubProgram.create :name => 'Fun sub Program', :program => prog
    initiative = Initiative.create
    assert_equal 3, initiative.errors.size
    initiative = Initiative.create :name => 'Fun Initiative'
    assert_equal 1, initiative.errors.size
    initiative = Initiative.create :name => 'Fun Initiative', :sub_program => sub_prog
    assert_not_nil initiative.id
  end
  
  test "ability to navigate to sub_initiatives" do
    prog = Program.create :name => 'Fun Program'
    sub_prog = SubProgram.create :name => 'Fun sub Program', :program => prog
    initiative = Initiative.create :name => 'Fun Program', :sub_program => sub_prog
    assert_not_nil initiative.sub_program.id
  end
end
