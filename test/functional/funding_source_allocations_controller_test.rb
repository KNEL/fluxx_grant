require 'test_helper'

class FundingSourceAllocationsControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    @FundingSourceAllocation = FundingSourceAllocation.make
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:funding_source_allocations)
  end
  
  test "should get CSV index" do
    get :index, :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:funding_source_allocations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create funding_source_allocation" do
    funding_source = FundingSource.make
    assert_difference('FundingSourceAllocation.count') do
      post :create, :funding_source_allocation => { :funding_source_id => funding_source.id }
    end

    assert 201, @response.status
    assert @response.header["Location"] =~ /#{funding_source_allocation_path(assigns(:funding_source_allocation))}$/
  end

  test "should show funding_source_allocation" do
    get :show, :id => @FundingSourceAllocation.to_param
    assert_response :success
  end

  test "should show funding_source_allocation with documents" do
    model_doc1 = ModelDocument.make(:documentable => @FundingSourceAllocation)
    model_doc2 = ModelDocument.make(:documentable => @FundingSourceAllocation)
    get :show, :id => @FundingSourceAllocation.to_param
    assert_response :success
  end
  
  test "should show funding_source_allocation with groups" do
    group = Group.make
    group_member1 = GroupMember.make :groupable => @FundingSourceAllocation, :group => group
    group_member2 = GroupMember.make :groupable => @FundingSourceAllocation, :group => group
    get :show, :id => @FundingSourceAllocation.to_param
    assert_response :success
  end
  
  test "should show funding_source_allocation with audits" do
    Audit.make :auditable_id => @FundingSourceAllocation.to_param, :auditable_type => @FundingSourceAllocation.class.name
    get :show, :id => @FundingSourceAllocation.to_param
    assert_response :success
  end
  
  test "should show funding_source_allocation audit" do
    get :show, :id => @FundingSourceAllocation.to_param, :audit_id => @FundingSourceAllocation.audits.first.to_param
    assert_response :success
  end
  
  test "should get edit" do
    get :edit, :id => @FundingSourceAllocation.to_param
    assert_response :success
  end

  test "should not be allowed to edit if somebody else is editing" do
    @FundingSourceAllocation.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @FundingSourceAllocation.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @FundingSourceAllocation.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @FundingSourceAllocation.to_param, :funding_source_allocation => {}
    assert assigns(:not_editable)
  end

  test "should update funding_source_allocation" do
    put :update, :id => @FundingSourceAllocation.to_param, :funding_source_allocation => {}
    assert flash[:info]
    
    assert 201, @response.status
    assert @response.header["Location"] =~ /#{funding_source_allocation_path(assigns(:funding_source_allocation))}$/
  end

  test "should destroy funding_source_allocation" do
    delete :destroy, :id => @FundingSourceAllocation.to_param
    assert_not_nil @FundingSourceAllocation.reload().deleted_at 
  end
end
