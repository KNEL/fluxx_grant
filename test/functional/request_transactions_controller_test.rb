require 'test_helper'

class RequestTransactionsControllerTest < ActionController::TestCase

  def setup
    @org = Organization.make
    @program = Program.make
    @request1 = GrantRequest.make :program => @program, :program_organization => @org
    @request_transaction1 = RequestTransaction.make :request => @request1
    @user1 = User.make
    login_as @user1
    
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:request_transactions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create request_transaction" do
    assert_difference('RequestTransaction.count') do
      post :create, :request_transaction => { :request_id => @request1.to_param, :amount_due => 93323, :due_at => Time.now.mdy }
    end

    assert 201, @response.status
    assert @response.header["Location"] =~ /#{request_transaction_path(assigns(:request_transaction))}$/
  end

  test "should show request_transaction" do
    get :show, :id => @request_transaction1.to_param
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => @request_transaction1.to_param
    assert_response :success
  end

  test "should update request_transaction" do
    put :update, :id => @request_transaction1.to_param, :request_transaction => {}
    assert flash[:info]
    
    assert 201, @response.status
    assert @response.header["Location"] =~ /#{request_transaction_path(assigns(:request_transaction))}$/
  end

  test "should destroy request_transaction" do
    delete :destroy, :id => @request_transaction1.id
    assert_not_nil @request_transaction1.reload().deleted_at 
    assert 201, @response.status
    assert @response.header["Location"] =~ /#{request_transaction_path(@request_transaction1)}$/
  end

  test "should not be allowed to edit if somebody else is editing" do
    @request_transaction1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @request_transaction1.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @request_transaction1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @request_transaction1.to_param, :organization => {}
    assert assigns(:not_editable)
  end
end