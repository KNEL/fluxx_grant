require 'test_helper'

class RequestEvaluationMetricsControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @request1 = GrantRequest.make 
  end
  
  test "should get new" do
    get :new, :request_id => @request1.id
    assert_response :success
  end
  
  test "should create request evaluation metric" do
    assert_difference('RequestEvaluationMetric.count') do
      post :create, :request_evaluation_metric => {:request_id => @request1.id, :description => Sham.sentence}
    end

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to user_organization_path(assigns(:user_organization))
    
    assert_equal @request1, assigns(:request_evaluation_metric).request
  end

  test "should get edit" do
    rfs = RequestEvaluationMetric.make
    get :edit, :id => rfs.id
    assert_response :success
  end

  test "should update organization" do
    rfs = RequestEvaluationMetric.make
    put :update, :id => rfs.id, :request_evaluation_metric => {:description => 'hello'}
    assert_redirected_to request_evaluation_metric_path(assigns(:request_evaluation_metric))
    assert_equal 'hello', assigns(:request_evaluation_metric).description
  end
  
  test "should destroy request_evaluation_metric" do
    rfs = RequestEvaluationMetric.make
    delete :destroy, :id => rfs.to_param
    assert_raises ActiveRecord::RecordNotFound do
      rfs.reload()
    end
    assert_redirected_to request_evaluation_metric_url(rfs)
  end
  
  test "should get request evaluation metrics list for given request" do
    get :index, :request_id => @request1.id
    assert_response :success
  end


end