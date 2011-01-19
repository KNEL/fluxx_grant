require 'test_helper'

class RequestTransactionFundingSourcesControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @RequestTransactionFundingSource = RequestTransactionFundingSource.make
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:request_transaction_funding_sources)
  end
  
  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create request_transaction_funding_source" do
    assert_difference('RequestTransactionFundingSource.count') do
      post :create, :request_transaction_funding_source => { :name => 'some random name for you' }
    end

    assert 201, @response.status
    assert @response.header["Location"] =~ /#{request_transaction_funding_source_path(assigns(:request_transaction_funding_source))}$/
  end

  test "should show request_transaction_funding_source" do
    get :show, :id => @RequestTransactionFundingSource.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @RequestTransactionFundingSource.to_param
    assert_response :success
  end

  test "should not be allowed to edit if somebody else is editing" do
    @RequestTransactionFundingSource.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @RequestTransactionFundingSource.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @RequestTransactionFundingSource.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @RequestTransactionFundingSource.to_param, :request_transaction_funding_source => {}
    assert assigns(:not_editable)
  end

  test "should update request_transaction_funding_source" do
    put :update, :id => @RequestTransactionFundingSource.to_param, :request_transaction_funding_source => {}
    assert flash[:info]
    
    assert 201, @response.status
    assert @response.header["Location"] =~ /#{request_transaction_funding_source_path(assigns(:request_transaction_funding_source))}$/
  end

  test "should destroy request_transaction_funding_source" do
    delete :destroy, :id => @RequestTransactionFundingSource.to_param
    assert_not_nil @RequestTransactionFundingSource.reload().deleted_at 
  end
end
