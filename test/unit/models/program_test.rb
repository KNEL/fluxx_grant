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
  
  test "make sure the funding_source_allocations call does not blow up" do
    result = @program.funding_source_allocations(:spending_year => 2010)
    result = @program.funding_source_allocations
  end
  
  test "make sure the total_pipeline call does not blow up" do
    result = @program.total_pipeline
    result = @program.total_pipeline 'GrantRequest'
    result = @program.total_pipeline ['GrantRequest']
    result = @program.total_pipeline ['GrantRequest', 'FipRequest']
  end
  
  test "make sure the total_allocation call does not blow up" do
    result = @program.total_allocation(:spending_year => 2010)
    result = @program.total_allocation
  end
end