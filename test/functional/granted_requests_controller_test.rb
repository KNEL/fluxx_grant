require 'test_helper'

class GrantedRequestsControllerTest < ActionController::TestCase
  def setup
    @org = Organization.make
    @program = Program.make
    @request1 = GrantRequest.make :program => @program, :program_organization => @org, :base_request_id => nil
    @user1 = User.make
    @user1.has_role! Program.program_officer_role_name, @program
    login_as @user1
  end

  test "test filter display" do
    get :index, :view => 'filter'
  end

  test "should show request" do
    get :show, :id => @request1.to_param
    assert_response :success
  end
end