require 'test_helper'

class InitiativeTest < ActiveSupport::TestCase
  test "ability to validate an initiative" do
    prog = Program.create :name => 'Fun Program'
    initiative = Initiative.create
    assert_equal 3, initiative.errors.size
    initiative = Initiative.create :name => 'Fun Initiative'
    assert_equal 1, initiative.errors.size
    initiative = Initiative.create :name => 'Fun Initiative', :program => prog
    assert_not_nil initiative.id
  end
  
  test "ability to navigate to sub_initiatives" do
    prog = Program.create :name => 'Fun Program'
    initiative = Initiative.create :name => 'Fun Program', :program => prog
    assert_not_nil initiative.program.id
  end
end
