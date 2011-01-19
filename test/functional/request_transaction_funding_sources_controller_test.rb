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
  
  test "should get CSV index" do
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:request_transaction_funding_sources)
  end

  test "autocomplete" do
    lookup_instance = RequestTransactionFundingSource.make
    get :index, :name => lookup_instance.name, :format => :autocomplete
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal lookup_instance.id, a.last['value']
  end

  test "should confirm that name_exists" do
    get :index, :name => @RequestTransactionFundingSource.name, :format => :autocomplete
    a = @response.body.de_json # try to deserialize the JSON to an array
    assert_equal @RequestTransactionFundingSource.id, a.first['value']
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

  test "should show request_transaction_funding_source with documents" do
    model_doc1 = ModelDocument.make(:documentable => @RequestTransactionFundingSource)
    model_doc2 = ModelDocument.make(:documentable => @RequestTransactionFundingSource)
    get :show, :id => @RequestTransactionFundingSource.to_param
    assert_response :success
  end
  
  test "should show request_transaction_funding_source with groups" do
    group = Group.make
    group_member1 = GroupMember.make :groupable => @RequestTransactionFundingSource, :group => group
    group_member2 = GroupMember.make :groupable => @RequestTransactionFundingSource, :group => group
    get :show, :id => @RequestTransactionFundingSource.to_param
    assert_response :success
  end
  
  test "should show request_transaction_funding_source with audits" do
    Audit.make :auditable_id => @RequestTransactionFundingSource.to_param, :auditable_type => @RequestTransactionFundingSource.class.name
    get :show, :id => @RequestTransactionFundingSource.to_param
    assert_response :success
  end
  
  test "should show request_transaction_funding_source audit" do
    get :show, :id => @RequestTransactionFundingSource.to_param, :audit_id => @RequestTransactionFundingSource.audits.first.to_param
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
