require 'test_helper'

class RequestLettersControllerTest < ActionController::TestCase

  def setup
    @user1 = User.make
    login_as @user1
    
    # Make a grant
    @org = Organization.make
    @program = Program.make
    @request1 = GrantRequest.make :program => @program, :program_organization => @org
    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 18
    @request1.amount_recommended = 45000
    @request1.become_grant
    @request1.grant_begins_at = Time.now + 1.month
    @request1.grant_agreement_at = Time.now
    @request1.save
    
    LetterTemplate.add_letter_template_reload_methods
    LetterTemplate.reload_all_requests_letters
    
    @request1.grant_agreement_letter_type = bp_attrs[:ga_letter_template].id
    @request1.award_letter_type = bp_attrs[:award_letter_template].id
    p "ESH: have @request1.award_letter_type=#{@request1.award_letter_type}"
    @request1.resolve_letter_type_changes
    @request1.save

    @request_letter = @request1.reload.grant_agreement_request_letter
    @request_letter2 = @request1.reload.award_request_letter
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:request_letters)
  end

  test "should show request_letter" do
    get :show, :id => @request_letter.to_param
    assert_response :success
  end

  test "should show request_letter2" do
    get :show, :id => @request_letter2.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @request_letter.to_param
    assert_response :success
  end

  test "should update request_letter" do
    put :update, :id => @request_letter.to_param, :request_letter => { }
    assert_redirected_to request_letter_path(assigns(:request_letter))
  end

  test "should destroy request_letter" do
    delete :destroy, :id => @request_letter.to_param
    assert_not_nil @request_letter.reload().deleted_at 
    assert_redirected_to request_letter_url(@request_letter)
  end

  test "should not be allowed to edit if somebody else is editing" do
    @request_letter.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @request_letter.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @request_letter.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @request_letter.to_param, :organization => {}
    assert assigns(:not_editable)
  end
end
