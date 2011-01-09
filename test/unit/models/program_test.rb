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
    role_user2 = RoleUser.make :user => user2, :roleable => @program, :name => 'vice president'
    assert_equal 2, @program.reload.load_users.size
    assert_equal user1.first_name, @program.load_users(role_user1.name).first.first_name
    assert_equal user2.first_name, @program.load_users(role_user2.name).first.first_name
  end
end