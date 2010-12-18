require 'test_helper'

class AdminCardsControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @AdminCard = AdminCard.make
  end
  
  test "should show admin_card" do
    get :show, :id => @AdminCard.to_param
    assert_response :success
  end

end
