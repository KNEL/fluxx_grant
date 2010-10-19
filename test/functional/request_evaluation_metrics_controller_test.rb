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
      post :create, :request_evaluation_metric => {:request_id => @request1.id}
    end

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to user_organization_path(assigns(:user_organization))
    
    assert_equal @funding_source, assigns(:request_evaluation_metric).funding_source
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
  
  test "should not be allowed to edit if somebody else is editing" do
    rfs = RequestEvaluationMetric.make
    rfs.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => rfs.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    rfs = RequestEvaluationMetric.make
    rfs.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => rfs.to_param
    assert assigns(:not_editable)
  end

  test "should get request evaluation metrics list for given request" do
    get :index, :request_id => @request1.id
    assert_response :success
  end


end