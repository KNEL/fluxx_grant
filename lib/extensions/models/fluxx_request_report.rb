module FluxxRequestReport
  SEARCH_ATTRIBUTES = [:grant_program_ids, :grant_sub_program_ids, :due_at, :report_type, :state, :updated_at, :grant_state, :favorite_user_ids] 
  LIQUID_METHODS = [:type_to_english, :due_at]

  def self.included(base)
    base.belongs_to :request
    base.belongs_to :grant, :class_name => 'GrantRequest', :foreign_key => 'request_id', :conditions => {:granted => true}
    
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.has_many :workflow_events, :as => :workflowable
    base.has_many :favorites, :conditions => {:favorable_type => 'RequestReport'}, :foreign_key => :favorable_id # Override the favorites association to let it include all request types

    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members

    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search
    base.insta_export do |insta|
      insta.filename = 'report'
      insta.headers = [['Date Created', :date], ['Date Updated', :date], 'Request ID', 'state', 'Report Type', ['Date Due', :date], ['Date Approved', :date], 'Org Name', 
            ['Amount Recommended', :currency], 'Lead PO', 'Project Summary']
      insta.sql_query = "select rd.created_at, rd.updated_at, requests.base_request_id request_id, rd.state, rd.report_type, rd.due_at, rd.approved_at, organizations.name program_org_name,
              requests.amount_recommended, 
              (select concat(users.first_name, (concat(' ', users.last_name))) full_name from
                users where id = program_lead_id) lead_po,
              requests.project_summary
              from request_reports rd
              left outer join requests on rd.request_id = requests.id
              left outer join organizations on requests.program_organization_id = organizations.id
              where rd.id IN (?)"
    end
    
    base.insta_favorite
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES + [:group_ids, :due_in_days, :overdue_by_days, :lead_user_ids]
      insta.derived_filters = {:due_in_days => (lambda do |search_with_attributes, request_params, name, value|
          value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now + value.to_i.days
            search_with_attributes[:due_at] = (0..due_date_check.to_i)
            search_with_attributes[:has_been_approved] = false
          end || {}
        end),
        :overdue_by_days => (lambda do |search_with_attributes, request_params, name, value|
          value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now - value.to_i.days
            search_with_attributes[:due_at] = (0..due_date_check.to_i)
            search_with_attributes[:has_been_approved] = false
          end || {}
        end),
        :grant_program_ids => (lambda do |search_with_attributes, request_params, name, val|
          program_id_strings = val
          programs = Program.where(:id => program_id_strings).all.compact
          program_ids = programs.map do |program| 
            children = program.children_programs
            if children.empty?
              program
            else
              children
            end
          end.compact.flatten.map &:id
          search_with_attributes[:grant_program_ids] = program_ids if program_ids && !program_ids.empty?
        end),
        }
    end
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at, :approved_at, :bjo_received_at] 
    end
    
    base.insta_template do |insta|
      insta.entity_name = 'request_report'
      insta.add_methods [:type_to_english]
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )

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
    
    # types:
    # RequestReport.eval_type_name => 'Eval',
    # RequestReport.final_budget_type_name => 'Final Financial',
    # RequestReport.final_narrative_type_name => 'Final Narrative',
    # RequestReport.interim_budget_type_name => 'Interim Financial',
    # RequestReport.interim_narrative_type_name => 'Interim Narrative',
    
    base.insta_workflow do |insta|
      insta.add_state_to_english RequestReport.new_state, 'New'
      insta.add_state_to_english RequestReport.pending_lead_approval_state, 'Pending Lead Approval'
      insta.add_state_to_english RequestReport.pending_grant_team_approval_state, 'Pending Grants Team Approval'
      insta.add_state_to_english RequestReport.pending_finance_approval_state, 'Pending Finance Approval'
      insta.add_state_to_english RequestReport.approved_state, 'Approved'
      insta.add_state_to_english RequestReport.sent_back_to_pa_state, 'Sent Back to PA'
      insta.add_state_to_english RequestReport.sent_back_to_lead_state, 'Sent Back to Lead'
      insta.add_state_to_english RequestReport.sent_back_to_grant_team_state, 'Sent Back to Grants Team'
      
      insta.add_event_to_english RequestReport.submit_report_event, 'Submit Report'
      insta.add_event_to_english RequestReport.lead_approve_event, 'Approve'
      insta.add_event_to_english RequestReport.lead_send_back_event, 'Send Back'
      insta.add_event_to_english RequestReport.grant_team_approve_event, 'Approve'
      insta.add_event_to_english RequestReport.grant_team_send_back_event, 'Send Back'
      insta.add_event_to_english RequestReport.finance_approve_event, 'Approve'
      insta.add_event_to_english RequestReport.finance_send_back_event, 'Send Back'

      insta.add_non_validating_event :reject
      insta.add_non_validating_event RequestReport.lead_send_back_event
      insta.add_non_validating_event RequestReport.grant_team_send_back_event
      insta.add_non_validating_event RequestReport.finance_send_back_event
    end
    
    base.add_sphinx if base.respond_to?(:sphinx_indexes) && !(base.connection.adapter_name =~ /SQLite/i)
  end

  module ModelClassMethods
    def add_sphinx
      define_index :req_report_first do
        # fields
        indexes grant.program_organization.name, :as => :request_org_name, :sortable => true
        indexes grant.program_organization.acronym, :as => :request_org_acronym, :sortable => true
        indexes "if(requests.type = 'FipRequest', concat('FG-',requests.base_request_id), concat('G-',requests.base_request_id))", :as => :request_grant_id, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, due_at 
        set_property :delta => :delayed
        has grant(:id), :as => :grant_ids
        has grant.program(:id), :as => :grant_program_ids
        has grant.sub_program(:id), :as => :grant_sub_program_ids
        has grant.state, :type => :string, :crc => true, :as => :grant_state
        has :report_type, :type => :string, :crc => true
        has :state, :type => :string, :crc => true
        has 'null', :type => :multi, :as => :favorite_user_ids
        has "IF(request_reports.state = 'approved', 1, 0)", :as => :has_been_approved, :type => :boolean
        has "CONCAT(IFNULL(`requests`.`program_organization_id`, '0'), ',', IFNULL(`requests`.`fiscal_organization_id`, '0'))", :as => :related_organization_ids, :type => :multi
        # TODO ESH: derive the following which are no longer basd on roles_users but instead on program_lead_requests, grantee_org_owner_requests, grantee_signatory_requests, fiscal_org_owner_requests, fiscal_signatory_requests
        # has request.lead_user_roles.roles_users.user(:id), :as => :lead_user_ids
        has group_members.group(:id), :type => :multi, :as => :group_ids
      end

      define_index :req_report_second do
        # fields
        indexes grant.program_organization.name, :as => :request_org_name, :sortable => true
        indexes 'null', :type => :string, :as => :request_org_acronym, :sortable => true
        indexes 'null', :type => :string, :as => :request_grant_id, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, due_at
        set_property :delta => :delayed
        has 'null', :type => :multi, :as => :grant_ids
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_sub_program_ids
        has 'null', :type => :multi, :type => :string, :crc => true, :as => :grant_state
        has :report_type, :type => :string, :crc => true
        has :state, :type => :string, :crc => true
        has favorites.user(:id), :as => :favorite_user_ids
        has "IF(request_reports.state = 'approved', 1, 0)", :as => :has_been_approved, :type => :boolean
        has 'null', :type => :multi, :as => :related_organization_ids
        # TODO ESH: derive the following which are no longer basd on roles_users but instead on program_lead_requests, grantee_org_owner_requests, grantee_signatory_requests, fiscal_org_owner_requests, fiscal_signatory_requests
        # has 'null', :type => :multi, :as => :lead_user_ids
        has 'null', :type => :multi, :as => :group_ids
      end
    end
    
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

    def document_title_name
      'Report'
    end
  end

  module ModelInstanceMethods
    def title
      "#{type_to_english} #{request ? request.grant_id : ''}"
    end


    def is_eval_report_type?
      report_type == RequestReport.eval_type_name
    end
    
    def is_final_type?
      is_final_budget_type? || is_final_narrative_type?
    end

    def is_final_budget_type?
      report_type == RequestReport.final_budget_type_name
    end

    def is_final_narrative_type?
      report_type == RequestReport.final_narrative_type_name
    end

    def is_interim_type?
      is_interim_budget_type? || is_interim_narrative_type?
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
    
    def related_users
      if request
        request.related_users
      end || []
    end
    
    def related_organizations
      if request
        request.related_organizations
      end || []
    end
    
    def related_grants
      [request]
    end
    
    def related_reports
      if request
        request.related_request_reports - [self]
      end || []
    end

    def is_approved?
      state == 'approved' && approved_at
    end

    def has_tax_class?
      grant && grant.has_tax_class?
    end

    def is_grant_er?
      grant && grant.is_er?
    end
    
    def adjust_request_transactions
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