require 'test_helper'

class GrantRequestTest < ActiveSupport::TestCase
  def setup
    @req = GrantRequest.make
  end
  
  test "create a request and check initial state transition" do
    assert_equal 'new', @req.state
  end

  test "create a new request and try to reject- should be able to" do
    @req.reject
  end

  test "create a request and check the amount_requested filter" do
    r = Request.new :amount_requested => "$200,000"
    assert_equal 200000, r.amount_requested
  end
  
  test "create a request and check the amount_recommended filter" do
    r = Request.new :amount_recommended => "$200,000"
    assert_equal 200000, r.amount_recommended
  end
  
  test "create a request and check the old_amount_funded filter" do
    r = Request.new :amount_recommended => "$200,000"
    assert_equal 200000, r.amount_recommended.to_i
  end

  test "create a request and try to reject" do
    Request.approval_chain.each do |cur_state|
      @req.state = cur_state
      @req.reject
      assert_equal 'rejected', @req.state
    end
  end

  test "create a request and try to unreject" do
    @req.state = 'rejected'
    @req.un_reject
    assert_equal 'new', @req.state
  end

  test "create a new request and recommend for funding" do
    @req.recommend_funding
    assert_equal 'funding_recommended', @req.state
  end

  test "create a new request and complete ierf" do
    @req.state = 'funding_recommended'
    @req.complete_ierf
    assert_equal 'pending_grant_team_approval', @req.state
  end

  test "create a sent_back_to_pa sentback request and complete ierf" do
    @req.state = 'sent_back_to_pa'
    @req.complete_ierf
    assert_equal 'pending_grant_team_approval', @req.state
  end

  test "create a request and grant_team approve" do
    @req.state = 'pending_grant_team_approval'
    @req.grant_team_approve
    assert_equal 'pending_po_approval', @req.state
  end

  test "create a request and grant_team approve then send back to PA" do
    @req.state = 'pending_grant_team_approval'
    @req.save
    assert_difference('WorkflowEvent.count') do
      @req.grant_team_approve
      @req.save
    end
    assert_equal 'pending_po_approval', @req.state
    @req.po_send_back
    @req.save
    assert_equal 'sent_back_to_pa', @req.state
    @req.complete_ierf
    @req.save
    assert_equal 'pending_po_approval', @req.state
  end

  test "create a request and po approve" do
    @req.state = 'pending_po_approval'
    @req.po_approve
    assert_equal 'pending_president_approval', @req.state
  end

  test "create a pd sent back request and po approve" do
    @req.state = 'sent_back_to_po'
    @req.po_approve
    assert_equal 'pending_president_approval', @req.state
  end

  test "send back by po" do
    @req.state = 'pending_po_approval'
    @req.po_send_back
    assert_equal 'sent_back_to_pa', @req.state
  end

  test "create a request and president approve" do
    @req.state = 'pending_president_approval'
    @req.president_approve
    assert_equal 'pending_grant_promotion', @req.state
  end

  test "send back by president" do
    @req.state = 'pending_president_approval'
    @req.president_send_back
    assert_equal 'sent_back_to_po', @req.state
  end

  test "request becomes a grant" do
    @req.state = 'pending_grant_promotion'
    @req.duration_in_months = 12
    @req.amount_recommended = 45000
    @req.become_grant
    assert_equal 'granted', @req.state
  end
  
  test "creating a request will result in an entry in the model deltas table" do
    max_realtime_id = RealtimeUpdate.maximum :id
    temp_req = nil
    assert_difference('Request.count') do
      temp_req = GrantRequest.make
    end
    after_max_realtime_id = RealtimeUpdate.maximum :id
    grant_request_rts = RealtimeUpdate.where(['id > ?', max_realtime_id]).where(:type_name => GrantRequest.name, :action => 'create').all
    assert_equal 1, grant_request_rts.size
    assert_equal temp_req.id, grant_request_rts.first.model_id
    model_delta = RealtimeUpdate.find :last
    assert_equal 'create', model_delta.action
  end
  
  test "updating a request will result in an entry in the model deltas table" do
    assert_difference('RealtimeUpdate.count') do
      result = @req.update_attributes :project_summary => 'howdy folks'
    end
    model_delta = RealtimeUpdate.find :last
    assert_equal 'update', model_delta.action
  end
  
  test "deleting a request will result in an entry in the model deltas table" do
    assert_difference('RealtimeUpdate.count') do
      @req.update_attributes :deleted_at => Time.now
    end
    model_delta = RealtimeUpdate.find :last
    assert_equal 'delete', model_delta.action
    assert_difference('RealtimeUpdate.count') do
      @req.destroy
    end
    model_delta = RealtimeUpdate.find :last
    assert_equal 'delete', model_delta.action
  end
  
  test 'create a blank request should include po' do
    assert @req.event_timeline.include?('pending_po_approval')
  end
  
  test 'end date should be the last of the month before duration months in the future from the start date' do
    @req.grant_begins_at = Time.parse '2010-03-01'
    
    assert_equal Time.utc(2011, 2, 28, 0, 0, 0), @req.grant_ends_at
  end
  
  test "create a grant and try to cancel" do
    @req.state = 'granted'
    @req.cancel_grant
    assert_equal 'canceled', @req.state
  end
  
  test "create program signatory roles, then remove program org, should get a null program signatory user and role" do
    request_with_program_org = GrantRequest.make :program_organization => Organization.make
    user = User.make
    request_with_program_org.grantee_org_owner = user
    request_with_program_org.save
    assert_equal user, request_with_program_org.grantee_org_owner
    request_with_program_org.program_organization = nil
    request_with_program_org.save
    assert !request_with_program_org.grantee_org_owner
  end
  
  test "create fiscal signatory roles, then remove fiscal org, should get a null fiscal signatory user and role" do
    request_with_fiscal_org = GrantRequest.make :fiscal_organization => Organization.make
    user = User.make
    request_with_fiscal_org.fiscal_org_owner = user
    request_with_fiscal_org.save
    assert_equal user, request_with_fiscal_org.fiscal_org_owner
    request_with_fiscal_org.fiscal_organization = nil
    request_with_fiscal_org.save
    assert !request_with_fiscal_org.fiscal_org_owner
  end
  
  test "test cascading deletes for request" do
    req_tran1 = RequestTransaction.make :request => @req
    req_tran2 = RequestTransaction.make :request => @req
    req_rep1 = RequestReport.make  :request => @req
    req_rep2 = RequestReport.make  :request => @req
    cur_user = User.make
    @req.safe_delete cur_user
    assert @req.reload.deleted_at
    assert req_tran1.reload.deleted_at
    assert req_tran2.reload.deleted_at
    assert req_rep1.reload.deleted_at
    assert req_rep2.reload.deleted_at
    
  end
end