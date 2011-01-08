require 'test_helper'

class ProgramTest < ActiveSupport::TestCase
  def setup
    @program = Program.make
  end
  
  test "test creating program" do
    assert @program.id
  end
  
  test "create a program and find the users" do
    user1 = User.make
    user2 = User.make
    role_user1 = RoleUser.make :user => user1, :roleable => @program, :name => 'president'
    role_user2 = RoleUser.make :user => user1, :roleable => @program, :name => 'vice president'
    assert_equal 2, @program.reload.load_users.size
    assert_equal role_user1.name, @program.load_users(role_user1.name).first.name
    assert_equal role_user2.name, @program.load_users(role_user2.name).first.name
  end
end