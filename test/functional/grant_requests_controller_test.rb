require 'test_helper'

class GrantRequestsControllerTest < ActionController::TestCase
  
  def check_models_are_updated
    assert_difference('WorkflowEvent.count') do
      yield
    end
  end
  
  def check_models_are_not_updated
    assert_difference('WorkflowEvent.count', 0) do
      yield
    end
  end
  
  def setup
    @org = Organization.make
    @program = Program.make
    @request1 = GrantRequest.make :program => @program, :program_organization => @org, :base_request_id => nil
    @user1 = User.make
    @user1.has_role! Program.program_officer_role_name, @program
    login_as @user1
  end
  
  # test "check on _allowed? methods" do
  #   @controller.session = @request.session
  #   @controller.load_request @request1.id
  #   assert @controller.reject_allowed?
  #   assert @controller.un_reject_allowed?
  #   assert @controller.recommend_funding_allowed?
  #   assert @controller.po_approve_allowed?
  #   assert @controller.po_send_back_allowed?
  #   assert !@controller.pd_approve_allowed?
  #   assert !@controller.pd_send_back_allowed?
  #   assert !@controller.svp_approve_allowed?
  #   assert !@controller.svp_send_back_allowed?
  #   assert !@controller.president_approve_allowed?
  #   assert !@controller.president_send_back_allowed?
  #   assert !@controller.become_grant_allowed?
  # end

  test "try to reject a request" do
     [(GrantRequest.approval_chain + GrantRequest.sent_back_states).first].each do |cur_state|
      @controller = GrantRequestsController.new
      Program.request_roles.each do |role_name|
        @request1.state = cur_state.to_s
        @request1.save
        login_as_user_with_role role_name
        check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'reject'}
        assert_equal 'rejected', @request1.reload().state
        assert flash[:info]
      end
    end
  end 

  test "try to unreject a request" do
    [Program.request_roles.first].each do |role_name|
      @request1.state = 'rejected'
      @request1.save
      login_as_user_with_role role_name
      check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'un_reject'}
      assert_equal 'new', @request1.reload().state
      assert flash[:info]
    end
  end 
  
  test "try to have PA recommend and approve a request" do
    login_as_user_with_role Program.program_associate_role_name
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'recommend_funding'}
    assert_equal 'funding_recommended', @request1.reload().state
    assert flash[:info]
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'complete_ierf'}
    assert_equal 'pending_grant_team_approval', @request1.reload().state
    assert flash[:info]
  end

  test "try to have PA complete a sent back request" do
    login_as_user_with_role Program.program_associate_role_name
    @request1.state = 'sent_back_to_pa'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'complete_ierf'}
    assert_equal 'pending_grant_team_approval', @request1.reload().state
    assert flash[:info]
  end
  
  test "try to have GrantAdmin recommend and approve a request" do
    login_as_user_with_role Program.grants_administrator_role_name
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'recommend_funding'}
    assert_equal 'funding_recommended', @request1.reload().state
    assert flash[:info]
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'complete_ierf'}
    assert_equal 'pending_grant_team_approval', @request1.reload().state
    assert flash[:info]

    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'grant_team_send_back'}
    assert_equal 'sent_back_to_pa', @request1.reload().state
    assert flash[:info]
  end

  test "try to have GrantAdmin send back a request" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'pending_grant_team_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'grant_team_send_back'}
    assert_equal 'sent_back_to_pa', @request1.reload().state
    assert flash[:info]
  end

  test "try to have GrantAdmin approve an already approved request and fail" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'pending_po_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'po_approve'}
    assert_equal 'pending_po_approval', @request1.reload().state
    assert flash[:error]
  end

  test "try to have PO recommend and approve a request" do
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'recommend_funding'}
    assert flash[:info]
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'complete_ierf'}
    assert_equal 'pending_grant_team_approval', @request1.reload().state
    assert flash[:info]

    @request1.state = 'pending_po_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'po_approve'}
    assert_equal 'pending_president_approval', @request1.reload().state
    assert flash[:info]
  end

  test "try to have PO send back a request" do
    @request1.state = 'pending_po_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'po_send_back'}
    assert_equal 'sent_back_to_pa', @request1.reload().state
    assert flash[:info]
  end

  test "try to have PO approve a sent back request" do
    @request1.state = 'sent_back_to_po'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'po_approve'}
    assert_equal 'pending_president_approval', @request1.reload().state
    assert flash[:info]
  end

  test "try to have PO approve an already approved request and fail" do
    @request1.state = 'pending_president_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'president_approve'}
    assert_equal 'pending_president_approval', @request1.reload().state
    assert flash[:error]
  end

  test "try to have president recommend and approve a request" do
    login_as_user_with_role Program.president_role_name
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'recommend_funding'}
    assert flash[:info]
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'complete_ierf'}
    assert_equal 'pending_grant_team_approval', @request1.reload().state
    assert flash[:info]
    @request1.state = 'pending_president_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'president_approve'}
    assert_equal 'pending_grant_promotion', @request1.reload().state
    assert flash[:info]
  end

  test "try to have president approve an already approved request and fail" do
    login_as_user_with_role Program.president_role_name
    @request1.state = 'pending_grant_promotion'
    @request1.save
    check_models_are_not_updated{put :update, :id => @request1.to_param, :event_action => 'president_approve'}
    assert_equal 'pending_grant_promotion', @request1.reload().state
    assert flash[:error]
  end

  test "try to have president send back a request" do
    login_as_user_with_role Program.president_role_name
    @request1.state = 'pending_president_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'president_send_back'}
    assert_equal 'sent_back_to_po', @request1.reload().state
    assert flash[:info]
  end
  
  test "Create a rollup-program, assign the president that role and try to approve a program in that rollup" do
    rollup_program = Program.make :rollup => true
    @program.parent_program = rollup_program
    @program.save
    
    login_as_user_with_role Program.president_role_name, rollup_program
    @request1.state = 'pending_president_approval'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'president_approve'}
    assert_equal 'pending_grant_promotion', @request1.reload().state
    assert flash[:info]
  end
  
  test "try to have grant assistant approve a request" do
    login_as_user_with_role Program.grants_assistant_role_name
    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 12
    @request1.amount_recommended = 45000
    @request1.save
    check_models_are_not_updated{put :edit, :id => @request1.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    er_request = assigns(:model)
  end

  test "try to have grant assistant approve an already approved request and make it closed" do
    login_as_user_with_role Program.grants_assistant_role_name
    @request1.state = 'closed'
    @request1.save
    check_models_are_not_updated{put :update, :id => @request1.to_param, :event_action => 'close_grant'}
    assert_equal 'closed', @request1.reload().state
  end

  test "try to have grant administrator approve a request" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 12
    @request1.amount_recommended = 45000
    @request1.save
    check_models_are_not_updated{put :edit, :id => @request1.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    er_request = assigns(:model)
  end

  test "try to have grant administrator approve an already approved request and make it closed" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'granted'
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'close_grant'}
    assert_equal 'closed', @request1.reload().state
    assert flash[:info]
  end
  
  test "test that approve a greater than 1 year duration request for a non-profit to become a grant adds 3 request documents and creates the grant ID" do
    assert_nil @request1.grant_id
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 18
    @request1.amount_recommended = 45000
    @request1.save
    assert_nil @request1.grant_id
    check_models_are_not_updated{put :edit, :id => @request1.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    @request1 = assigns(:model)
    assert_equal 5, @request1.request_reports.size
    assert @request1.request_reports.first.report_type == RequestReport.interim_budget_type_name
    assert @request1.request_reports[1].report_type == RequestReport.interim_narrative_type_name
    assert @request1.request_reports[2].report_type == RequestReport.final_budget_type_name
    assert @request1.request_reports[3].report_type == RequestReport.final_narrative_type_name
    assert @request1.grant_id
  end
  
  test "test that approve a less than 1 year duration request for a new non-profit to become a grant for a new organization adds 3 request documents and creates the grant ID" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 11
    @request1.amount_recommended = 45000
    @request1.save
    assert !@request1.grant_id
    check_models_are_not_updated{put :edit, :id => @request1.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    @request1 = assigns(:model)
    assert_equal 5, @request1.request_reports.size
    assert @request1.request_reports.first.report_type == RequestReport.interim_budget_type_name
    assert @request1.request_reports[1].report_type == RequestReport.interim_narrative_type_name
    assert @request1.request_reports[2].report_type == RequestReport.final_budget_type_name
    assert @request1.request_reports[3].report_type == RequestReport.final_narrative_type_name
    assert @request1.request_reports.last.report_type == RequestReport.eval_type_name

    assert @request1.grant_id
  end
  
  test "test that approve a less than 1 year duration request to become a grant for an existing organization adds 2 request documents and creates the grant ID" do
    login_as_user_with_role Program.grants_administrator_role_name

    # Setup an extra grant
    @request2 = GrantRequest.make :state => 'granted', :program => @program, :program_organization => @org, :amount_recommended => 45000, :duration_in_months => 18, :granted => 1
    assert_equal 1, @org.grants.size

    @request1.state = 'pending_grant_promotion'
    @request1.duration_in_months = 11
    @request1.amount_recommended = 45000
    @request1.save
    assert !@request1.grant_id
    check_models_are_not_updated{put :edit, :id => @request1.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    @request1 = assigns(:model)
    assert @request1.grant_agreement_at
    assert_equal @org, @request1.program_organization
    assert_equal 3, @request1.request_reports.size
    assert @request1.request_reports[2].report_type == RequestReport.eval_type_name
    assert_equal 1, @request1.request_transactions.size
    assert_equal @request1.amount_recommended, @request1.request_transactions.first.amount_due
    
    assert @request1.grant_id
  end
  
  test "test approving a short durection ER untrusted org request" do
    program = Program.make
    login_as_user_with_role Program.grants_administrator_role_name, program
    er_org = Organization.make :tax_class => bp_attrs[:er_tax_status]
    er_request = GrantRequest.make :state => 'pending_grant_promotion', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 11
    check_models_are_not_updated{put :edit, :id => er_request.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    er_request = assigns(:model)
    assert er_request.grant_agreement_at
    assert_equal 5, er_request.request_reports.size
    assert_equal 3, er_request.request_transactions.size
  end
  
  test "test approving a long duration ER untrusted org request" do
    program = Program.make
    login_as_user_with_role Program.grants_administrator_role_name, program
    er_org = Organization.make :tax_class => bp_attrs[:er_tax_status]
    er_request = GrantRequest.make :state => 'pending_grant_promotion', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18
    assert_equal er_org, er_request.program_organization
    check_models_are_not_updated{put :edit, :id => er_request.to_param, :approve_grant_details => true}
    assert flash[:error]
  end

  test "test approving a short durection ER trusted org request" do
    program = Program.make
    login_as_user_with_role Program.grants_administrator_role_name, program
    er_org = Organization.make :tax_class => bp_attrs[:er_tax_status]
    er_grant = GrantRequest.make :state => 'granted', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18, :granted => true
    er_request = GrantRequest.make :state => 'pending_grant_promotion', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 11
    check_models_are_not_updated{put :edit, :id => er_request.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    er_request = assigns(:model)
    assert er_request.grant_agreement_at
    assert_equal 3, er_request.request_reports.size
    assert_equal 2, er_request.request_transactions.size
  end
  
  test "test advancing a long duration ER trusted org request in the grant workflow" do
    program = Program.make
    login_as_user_with_role Program.grants_administrator_role_name, program
    er_org = Organization.make :tax_class => bp_attrs[:er_tax_status]
    er_grant = GrantRequest.make :state => 'granted', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18, :granted => 1
    er_request = GrantRequest.make :state => 'pending_grant_promotion', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18
    assert er_request.has_tax_class?
    
    check_models_are_not_updated{put :edit, :id => er_request.to_param, :approve_grant_details => true}
    assert_template :partial => '_approve_grant_details'
    er_request = assigns(:model)
    assert er_request.grant_agreement_at
    assert_equal 1, er_org.grants.size
    assert_equal 5, er_request.request_reports.size
    assert_equal 3, er_request.request_transactions.size
  end
  
  test "test approving a long duration ER trusted org request" do
    program = Program.make
    login_as_user_with_role Program.grants_administrator_role_name, program
    er_org = Organization.make :tax_class => bp_attrs[:er_tax_status]
    er_grant = GrantRequest.make :state => 'granted', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18, :granted => true
    er_request = GrantRequest.make :state => 'pending_grant_promotion', :program => program, :program_organization => er_org, :amount_recommended => 45000, :duration_in_months => 18
    assert er_request.has_tax_class?
    assert_equal er_org, er_request.program_organization
    check_models_are_updated{put :update, :id => er_request.to_param, :event_action => 'become_grant', :grant_request => {:grant_agreement_at => Time.now}}
    assert_equal 'granted', er_request.reload().state
  end
  
  test "should get index for multiple pages of contents" do
    30.times {GrantRequest.make :program => @program, :program_organization => @org, :base_request_id => nil}
    get :index
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end
  
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end
  
  test "should get index with program_id" do
    get :index, :program_id => [@program.id]
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end
  
  test "should get index with funding_agreement_from_date" do
    get :index, :funding_agreement_from_date => [Time.now.mdy]
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end

  test "should get index with funding_agreement_to_date" do
    get :index, :funding_agreement_to_date => [Time.now.mdy]
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end

  test "should get CSV non-grants index" do
    get :index, :granted => [0], :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end
  
  test "should get CSV grants index" do
    get :index, :granted => [1], :format => 'csv'
    assert_response :success
    assert_not_nil assigns(:grant_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create request" do
    assert_difference('GrantRequest.count') do
      post :create, :grant_request => { :project_summary => Sham.sentence, :program_organization_id => @org.id, :duration_in_months => 12, :program_id => @program.id, :amount_requested => 45000 }
    end
    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to grant_request_path(assigns(:grant_request))
  end

  test "should choose a request letter for a request that currently has none" do
    @request1.save
    award_letter = LetterTemplate.make :category => LetterTemplate.award_category
    ga_letter = LetterTemplate.make :category => LetterTemplate.grant_agreement_category
    assert_difference('RequestLetter.count', 2) do
      put :update, :id => @request1.to_param, :grant_request => { :award_letter_type => award_letter.id, :grant_agreement_letter_type => ga_letter.id }
      @request1.reload.request_letters.each do |rl|
      end
    end
  end
  
  test "should not create new request letters for a request that currently has that letter template chosen" do
    @request1.save
    award_letter = LetterTemplate.make :category => LetterTemplate.award_category
    ga_letter = LetterTemplate.make :category => LetterTemplate.grant_agreement_category
    RequestLetter.create :request => @request1, :letter_template => award_letter
    RequestLetter.create :request => @request1, :letter_template => ga_letter
    assert_difference('RequestLetter.count', 0) do
      put :update, :id => @request1.to_param, :grant_request => { :award_letter_type => award_letter.id, :grant_agreement_letter_type => ga_letter.id }
    end
  end
  
  test "should update the request letters for a request that currently has a different letter template chosen" do
    @request1.save
    award_letter = LetterTemplate.make :category => LetterTemplate.award_category
    ga_letter = LetterTemplate.make :category => LetterTemplate.grant_agreement_category
    award_letter2 = LetterTemplate.make :category => LetterTemplate.award_category
    ga_letter2 = LetterTemplate.make :category => LetterTemplate.grant_agreement_category
    RequestLetter.create :request => @request1, :letter_template => award_letter
    RequestLetter.create :request => @request1, :letter_template => ga_letter
    assert_difference('RequestLetter.count', 0) do
      put :update, :id => @request1.to_param, :grant_request => { :award_letter_type => award_letter2.id, :grant_agreement_letter_type => ga_letter2.id }
    end
    
    @request1.reload.grant_agreement_letter_type
    assert_equal award_letter2.id, @request1.reload.load_award_letter_type
    assert_equal ga_letter2.id, @request1.reload.load_grant_agreement_letter_type
  end
  
  test "should create role grantee org owner user" do
    assert_difference('Request.count') do
      post :create, :grant_request => { :project_summary => Sham.sentence, :program_organization_id => @org.id, :grantee_org_owner_id => @user1.id, :duration_in_months => 12, :amount_requested => 45000, :program_id => @program.id }
    end
    request = assigns(:grant_request)
    assert_not_nil request
    assert_not_nil request.reload.grantee_org_owner
    assert_equal @user1.id, request.grantee_org_owner.id

    # Figure out how to determine a 201 and the options therein; some HTTP header in the @response object
    # assert_redirected_to grant_request_path(assigns(:grant_request))
  end

  test "should show request" do
    get :show, :id => @request1.to_param
    assert_response :success
  end

  test "should show request audit" do
    get :show, :id => @request1.to_param, :audit_id => @request1.audits.first.to_param
    assert_response :success
  end

  test "should show request finance tracker" do
    get :show, :id => @request1.to_param, :mode => 'finance_tracker'
    assert_response :success
  end

  test "try to show a deleted request" do
    @request1.update_attributes :deleted_at => Time.now
    get :show, :id => @request1.to_param
    assert_response :success
    assert @response.body.index @request1.to_param.to_s
  end

  test "should get edit" do
    get :edit, :id => @request1.to_param
    assert_response :success
  end

  test "should update request" do
    put :update, :id => @request1.to_param, :grant_request => { }
    assert_redirected_to grant_request_path
  end

  test "should destroy request" do
    delete :destroy, :id => @request1.to_param
    assert_not_nil @request1.reload().deleted_at 
    assert_redirected_to grant_request_path
  end
  
  test "test filter display" do
    get :filter
  end
  
  test "should not be allowed to edit if somebody else is editing" do
    @request1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    get :edit, :id => @request1.to_param
    assert assigns(:not_editable)
  end

  test "should not be allowed to update if somebody else is editing" do
    @request1.update_attributes :locked_until => (Time.now + 5.minutes), :locked_by_id => User.make.id
    put :update, :id => @request1.to_param, :organization => {}
    assert assigns(:not_editable)
  end

  test "try to cancel a grant" do
    login_as_user_with_role Program.grants_administrator_role_name
    @request1.state = 'granted'
    @request1.granted = true
    @request1.save
    check_models_are_updated{put :update, :id => @request1.to_param, :event_action => 'cancel_grant'}
    assert_equal 'canceled', @request1.reload().state
    assert flash[:info]
  end 
  
  # TODO ESH: need to test the calculate_button_names method to make sure we show the edit/delete/reject/un-reject/send-back buttons at the right times with the right names
end
