module FluxxRequestReport
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :grant, :class_name => 'GrantRequest', :foreign_key => 'request_id', :conditions => {:granted => true}
    
    base.has_many :model_documents, :as => :documentable
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.has_many :workflow_events, :as => :workflowable
    base.has_many :favorites, :conditions => {:favorable_type => 'RequestReport'}, :foreign_key => :favorable_id # Override the favorites association to let it include all request types
    base.has_many :notes, :conditions => {:deleted_at => nil, :notable_type => 'RequestReport'}, :foreign_key => :notable_id

    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta], :protect => true})

    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at, :approved_at, :bjo_received_at] 
    end

    base.send :include, AASM
    base.aasm_column :state
    base.aasm_initial_state :new

    base.aasm_state :new
    base.aasm_state :pending_lead_approval
    base.aasm_state :pending_grant_team_approval
    base.aasm_state :pending_finance_approval
    base.aasm_state :approved, :enter => :adjust_request_transactions
    base.aasm_state :sent_back_to_pa
    base.aasm_state :sent_back_to_lead
    base.aasm_state :sent_back_to_grant_team

    base.aasm_event :submit_report do
      transitions :from => :new, :to => :pending_lead_approval
      transitions :from => :sent_back_to_pa, :to => :pending_lead_approval
    end

    base.aasm_event :lead_approve do
      transitions :from => [:pending_lead_approval, :sent_back_to_lead], :to => :pending_grant_team_approval
    end

    base.aasm_event :lead_send_back do
      transitions :from => [:pending_lead_approval, :sent_back_to_lead], :to => :sent_back_to_pa
    end

    base.aasm_event :grant_team_approve do
      transitions :from => [:sent_back_to_grant_team, :pending_grant_team_approval], :to => :pending_finance_approval, :guard => (lambda { |rep| rep.is_grant_er? && rep.is_final_budget_type? })
      transitions :from => [:sent_back_to_grant_team, :pending_grant_team_approval], :to => :approved, :guard => (lambda { |rep| !(rep.is_grant_er? && rep.is_final_budget_type?) })
    end

    base.aasm_event :grant_team_send_back do
      transitions :from => [:sent_back_to_grant_team, :pending_grant_team_approval], :to => :sent_back_to_lead
    end

    base.aasm_event :finance_approve do
      transitions :from => :pending_finance_approval, :to => :approved
    end

    base.aasm_event :finance_send_back do
      transitions :from => :pending_finance_approval, :to => :sent_back_to_grant_team
    end
    
    
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def eval_type_name
      'Eval'
    end

    def final_budget_type_name
      'FinalBudget'
    end

    def final_narrative_type_name
      'FinalNarrative'
    end

    def interim_budget_type_name
      'InterimBudget'
    end

    def interim_narrative_type_name
      'InterimNarrative'
    end

    def report_doc_types
      [interim_budget_type_name, interim_narrative_type_name, final_budget_type_name, final_narrative_type_name, eval_type_name]
    end

    def type_to_english_translation report_type
      case report_type
        when RequestReport.eval_type_name then 'Eval'
        when RequestReport.final_budget_type_name then 'Final Financial'
        when RequestReport.final_narrative_type_name then 'Final Narrative'
        when RequestReport.interim_budget_type_name then 'Interim Financial'
        when RequestReport.interim_narrative_type_name then 'Interim Narrative'
        else
          report_type.to_s
      end
    end
    
    def submit_report_event
      'submit_report'
    end
    def lead_approve_event
      'lead_approve'
    end
    def lead_send_back_event
      'lead_send_back'
    end
    def grant_team_approve_event
      'grant_team_approve'
    end
    def grant_team_send_back_event
      'grant_team_send_back'
    end
    def finance_approve_event
      'finance_approve'
    end
    def finance_send_back_event
      'finance_send_back'
    end
    def send_back_events
      [RequestReport.lead_send_back_event.to_sym, RequestReport.grant_team_send_back_event.to_sym, RequestReport.finance_send_back_event.to_sym]
    end
    def promotion_events
      [RequestReport.submit_report_event.to_sym, RequestReport.lead_approve_event.to_sym, RequestReport.grant_team_approve_event.to_sym, RequestReport.finance_approve_event.to_sym]
    end

    def event_to_english_translation event_name
      case event_name.to_s
      when RequestReport.submit_report_event then 'Submit Report'
      when RequestReport.lead_approve_event then 'Approve'
      when RequestReport.lead_send_back_event then 'Send Back'
      when RequestReport.grant_team_approve_event then 'Approve'
      when RequestReport.grant_team_send_back_event then 'Send Back'
      when RequestReport.finance_approve_event then 'Approve'
      when RequestReport.finance_send_back_event then 'Send Back'
      else
        event_name.to_s
      end
    end

    def new_state
      'new'
    end
    def pending_lead_approval_state
      'pending_lead_approval'
    end
    def pending_grant_team_approval_state
      'pending_grant_team_approval'
    end
    def pending_finance_approval_state
      'pending_finance_approval'
    end
    def approved_state
      'approved'
    end
    def sent_back_to_pa_state
      'sent_back_to_pa'
    end
    def sent_back_to_lead_state
      'sent_back_to_lead'
    end
    def sent_back_to_grant_team_state
      'sent_back_to_grant_team'
    end

    def states
      [RequestReport.new_state.to_sym, RequestReport.pending_lead_approval_state.to_sym, RequestReport.pending_grant_team_approval_state.to_sym, 
        RequestReport.pending_finance_approval_state.to_sym, RequestReport.approved_state.to_sym, RequestReport.sent_back_to_pa_state.to_sym, 
        RequestReport.sent_back_to_lead_state.to_sym, RequestReport.sent_back_to_grant_team_state.to_sym]
    end

    def state_to_english
      RequestReport.state_to_english_translation self.state
    end

    def state_to_english_translation state_name
      case state_name.to_s
      when RequestReport.new_state then 'New'
      when RequestReport.pending_lead_approval_state then 'Pending Lead Approval'
      when RequestReport.pending_grant_team_approval_state then 'Pending Grants Team Approval'
      when RequestReport.pending_finance_approval_state then 'Pending Finance Approval'
      when RequestReport.approved_state then 'Approved'
      when RequestReport.sent_back_to_pa_state then 'Sent Back to PA'
      when RequestReport.sent_back_to_lead_state then 'Sent Back to Lead'
      when RequestReport.sent_back_to_grant_team_state then 'Sent Back to Grants Team'
      else
        state_name.to_s
      end
    end
  end

  module ModelInstanceMethods
    def title
      "#{type_to_english} #{request ? request.grant_id : ''}"
    end


    def is_eval_report_type?
      report_type == RequestReport.eval_type_name
    end

    def is_final_budget_type?
      report_type == RequestReport.final_budget_type_name
    end

    def is_final_narrative_type?
      report_type == RequestReport.final_narrative_type_name
    end

    def is_interim_budget_type?
      report_type == RequestReport.interim_budget_type_name
    end


    def is_interim_narrative_type?
      report_type == RequestReport.interim_narrative_type_name
    end


    def type_to_english
      RequestReport.type_to_english_translation report_type
    end

    def grant_state
      grant.state if grant
    end

    def grant_program_ids
      if grant && grant.program
        [grant.program.id]
      else
        []
      end
    end

    def grant_sub_program_ids
      if grant && grant.sub_program
        [grant.sub_program.id]
      else
        []
      end
    end

    def has_tax_class?
      grant && grant.has_tax_class?
    end

    def is_grant_er?
      grant && grant.is_er?
    end

    def adjust_request_transactions
      # TODO ESH: confirm the exact functionality here; do we want to wait until all interim/final reports are approved or how does it work??
      self.approved_at = Time.now
      if self.report_type == 'InterimBudget' || self.report_type == 'InterimNarrative'
        request.request_transactions.each do |rt|
          if rt.tentatively_due? && rt.request_document_linked_to == 'interim_request'
            rt.mark_actually_due 
            rt.save
          end
        end
      elsif self.report_type == 'FinalBudget' || self.report_type == 'FinalNarrative'
        request.request_transactions.each do |rt|
          if rt.tentatively_due? && rt.request_document_linked_to == 'final_request'
            rt.mark_actually_due 
            rt.save
          end
        end
      end
    end
  end
end