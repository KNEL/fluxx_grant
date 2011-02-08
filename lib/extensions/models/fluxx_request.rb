module FluxxRequest
  def self.prepare_from_date search_with_attributes, name, val
    if (Time.parse(val) rescue nil)
      start_at = Time.parse(val)
      if search_with_attributes[name] && search_with_attributes[name].end < FAR_IN_THE_FUTURE
        search_with_attributes[name] = (start_at.to_i..(search_with_attributes[name].end))
      else
        search_with_attributes[name] = (start_at.to_i..FAR_IN_THE_FUTURE.to_i)
      end
      search_with_attributes
    end || {}
  end
  
  def self.prepare_to_date search_with_attributes, name, val
    if (Time.parse(val) rescue nil)
      end_at = Time.parse(val)
      if search_with_attributes[name] && search_with_attributes[name].begin > 0
        search_with_attributes[name] = ((search_with_attributes[name].begin)..end_at.to_i)
      else
        search_with_attributes[name] = (0..end_at.to_i)
      end
      search_with_attributes
    end || {}
  end
  
  SEARCH_ATTRIBUTES = [:program_id, :sub_program_id, :created_by_id, :filter_state, :program_organization_id, :fiscal_organization_id, :favorite_user_ids, :lead_user_ids, :org_owner_user_ids, :granted, :filter_type]
  FAR_IN_THE_FUTURE = Time.now + 1000.year
  begin FAR_IN_THE_FUTURE.to_i rescue FAR_IN_THE_FUTURE = Time.now + 10.year end

  # for liquid_methods info see: https://github.com/tobi/liquid/blob/master/lib/liquid/module_ex.rb
  LIQUID_METHODS = [:grant_id, :project_summary, :grant_agreement_at, :grant_begins_at, :grant_ends_at, :request_received_at, :ierf_start_at, :fip_projected_end_at, :amount_requested, :amount_recommended, :duration_in_months, :program_lead, :signatory_contact, :signatory_user_org, :signatory_user_org_title, :address_org, :program, :initiative, :sub_program, :request_transactions, :request_reports, :request_evaluation_metrics, :letter_project_summary_without_leading_to]  

  def self.included(base)
    base.belongs_to :program_organization, :class_name => 'Organization', :foreign_key => :program_organization_id
    base.send :attr_accessor, :program_organization_lookup
    base.belongs_to :fiscal_organization, :class_name => 'Organization', :foreign_key => :fiscal_organization_id
    base.send :attr_accessor, :fiscal_organization_lookup
    base.has_many :request_organizations
    base.has_many :request_users
    base.has_many :request_transactions
    base.accepts_nested_attributes_for :request_transactions, :allow_destroy => true
    base.has_many :request_funding_sources
    base.has_many :request_evaluation_metrics
    base.has_one :grant_approved_event, :class_name => 'WorkflowEvent', :conditions => {:workflowable_type => base.name, :new_state => 'granted'}, :foreign_key => :workflowable_id
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.has_many :wiki_documents, :as => :model
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})

    base.belongs_to :program
    base.belongs_to :sub_program
    base.after_create :generate_request_id
    base.after_save :process_before_save_blocks
    base.after_save :handle_cascading_deletes
    
    # base.after_commit :update_related_data
    base.send :attr_accessor, :before_save_blocks

    base.send :attr_accessor, :force_all_request_programs_approved

    base.has_many :request_reports, :conditions => 'request_reports.deleted_at IS NULL'
    base.has_many :letter_request_reports, :class_name => 'RequestReport', :foreign_key => :request_id, :conditions => "request_reports.deleted_at IS NULL AND request_reports.report_type <> 'Eval'"
    base.accepts_nested_attributes_for :request_reports, :allow_destroy => true
    
    base.has_many :request_programs
    base.has_many :un_approved_request_programs, :class_name => 'RequestProgram', :foreign_key => 'request_id', :conditions => {:state => 'new'}
    base.accepts_nested_attributes_for :request_programs, :allow_destroy => true
    base.has_many :secondary_programs, :class_name => 'Program', :through => :request_programs, :source => :program
    
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    
    base.belongs_to :program_lead, :class_name => 'User', :foreign_key => 'program_lead_id'
    base.belongs_to :grantee_org_owner, :class_name => 'User', :foreign_key => 'grantee_org_owner_id'
    base.belongs_to :grantee_signatory, :class_name => 'User', :foreign_key => 'grantee_signatory_id'
    base.belongs_to :fiscal_org_owner, :class_name => 'User', :foreign_key => 'fiscal_org_owner_id'
    base.belongs_to :fiscal_signatory, :class_name => 'User', :foreign_key => 'fiscal_signatory_id'
    
    base.insta_favorite

    base.insta_lock
    base.insta_export do |insta|
      insta.filename = (lambda { |with_clause| (with_clause != nil && with_clause[:granted]==1) ? 'grant' : 'request'})
      insta.headers = (lambda do |with_clause|
          block1 = ['Request ID', 'Request Type', 'Status', ['Amount Requested', :currency], ['Amount Recommended', :currency]]
          grant_block = [['Amount Funded', :currency], ['Total Paid', :currency], ['Total Due', :currency], ['Grant Agreement Date', :date], ['Grant Start Date', :date], ['Grant End Date', :date]]
          block2 = ['Grantee', 'Grantee Street Address', 'Grantee Street Address2', 'Grantee City', 'Grantee State', 'Grantee Country', 'Grantee Postal Code', 'Grantee URL',
            'Fiscal Org', 'Fiscal Street Address', 'Fiscal Street Address2', 'Fiscal City', 'Fiscal State', 'Fiscal Country', 'Fiscal Postal Code', 'Fiscal URL',
            'Lead PO/PD', 'Program', 'Sub Program', ['Date Request Received', :date], ['Duration', :integer], 
            'Constituents', 'Means', 'Type of Org', 'Funding Source', ['Date Created', :date], ['Date Last Updated', :date], 
            'Primary Contact First Name', 'Primary Contact Last Name', 'Primary Contact Email',
            'Signatory First Name', 'Signatory Last Name', 'Signatory Email',
            'Request Summary']
          if with_clause && with_clause[:granted]==1
            block1 + grant_block + block2
          else
            block1 + block2
          end
        end)
      insta.sql_query =   (lambda do |with_clause|
          block1 = "  select 
          requests.base_request_id, requests.type, requests.state,
                         requests.amount_requested,
                         requests.amount_recommended,"

          grant_block =  "requests.amount_recommended amount_funded,
                         (select sum(amount_paid) from request_transactions rt where rt.request_id = requests.id) total_amount_paid, 
                         (select sum(amount_due) from request_transactions rt where rt.request_id = requests.id) total_amount_due,
                         requests.grant_agreement_at, 
                         grant_begins_at, 
                         date_add(date_add(grant_begins_at, interval duration_in_months MONTH), interval -1 DAY) grant_ends_at,"

          block2 = "program_organization.name, 
          program_organization.street_address program_org_street_address, program_organization.street_address2 program_org_street_address2, program_organization.city program_org_city,
          program_org_country_states.name program_org_state_name, program_org_countries.name program_org_country_name, program_organization.postal_code program_org_postal_code,
          program_organization.url program_org_url,
          fiscal_organization.name,
          fiscal_organization.street_address fiscal_org_street_address, fiscal_organization.street_address2 fiscal_org_street_address2, fiscal_organization.city fiscal_org_city,
          fiscal_org_country_states.name fiscal_org_state_name, fiscal_org_countries.name fiscal_org_country_name, fiscal_organization.postal_code fiscal_org_postal_code,
          fiscal_organization.url fiscal_org_url,
          (select concat(users.first_name, (concat(' ', users.last_name))) full_name from
          users where id = program_lead_id) lead_po,
          program.name, sub_program.name,
          requests.request_received_at, 
          requests.duration_in_months,
          (select replace(group_concat(mev.value, ', '), ', ', '')
          from multi_element_values mev, multi_element_groups meg, multi_element_choices mec
          WHERE   meg.name = 'constituents' and meg.target_class_name = 'Request'
          and multi_element_group_id = meg.id
          and multi_element_value_id = mev.id
          and target_id = requests.id
          group by requests.id) constituents,
          (select replace(group_concat(mev.value, ', '), ', ', '')
          from multi_element_values mev, multi_element_groups meg, multi_element_choices mec
          WHERE   (meg.name = 'usa_means' OR meg.name = 'china_means') and meg.target_class_name = 'Request'
          and multi_element_group_id = meg.id
          and multi_element_value_id = mev.id
          and target_id = requests.id
          group by requests.id) means,
          (select mev_tax_class.value from
           multi_element_groups meg_tax_class,
           multi_element_values mev_tax_class 
           WHERE meg_tax_class.name = 'tax_classes' and meg_tax_class.target_class_name = 'Request' and
           multi_element_group_id = meg_tax_class.id and program_organization.tax_class_id = mev_tax_class.id) org_tax_class,
          replace(group_concat(funding_sources.name, ', '), ', ', '') funding_source_name,
          requests.created_at, requests.updated_at, 
          owner_users.first_name, owner_users.last_name, owner_users.email,
          signatory_users.first_name, signatory_users.last_name, signatory_users.email,
          project_summary
                         FROM requests
                         LEFT OUTER JOIN programs program ON program.id = requests.program_id
                         LEFT OUTER JOIN sub_programs sub_program ON sub_program.id = requests.sub_program_id
                         LEFT OUTER JOIN organizations program_organization ON program_organization.id = requests.program_organization_id
                         LEFT OUTER JOIN organizations fiscal_organization ON fiscal_organization.id = requests.fiscal_organization_id
                         LEFT OUTER JOIN request_funding_sources ON request_funding_sources.request_id = requests.id
                         LEFT OUTER JOIN funding_source_allocations ON funding_source_allocations.id = request_funding_sources.funding_source_allocation_id
                         LEFT OUTER JOIN funding_sources ON funding_sources.id = funding_source_allocations.funding_source_id
                         left outer join geo_states as program_org_country_states on program_org_country_states.id = program_organization.geo_state_id
                         left outer join geo_countries as program_org_countries on program_org_countries.id = program_organization.geo_country_id
                         left outer join geo_states as fiscal_org_country_states on fiscal_org_country_states.id = fiscal_organization.geo_state_id
                         left outer join geo_countries as fiscal_org_countries on fiscal_org_countries.id = fiscal_organization.geo_country_id
                         left outer join users as owner_users on requests.program_lead_id = owner_users.id
                         left outer join users as signatory_users on requests.grantee_signatory_id = signatory_users.id
                         WHERE requests.id IN (?) GROUP BY requests.id"
         if with_clause[:granted]==1 || (with_clause[:granted].is_a?(Array) && with_clause[:granted].include?(1))
           block1 + grant_block + block2
         else
           block1 + block2
         end
       end)
    end

    base.insta_multi
    base.insta_lock
    
    base.insta_template do |insta|
      insta.entity_name = 'request'
      insta.add_methods [:program_organization, :signatory_contact, :address_org, :title, :grant_id, :request_id, :grant_ends_at]
      insta.add_list_method :request_transactions, RequestTransaction
      insta.add_list_method :request_reports, RequestReport
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )
    
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES + [:group_ids, :greater_amount_recommended, :lesser_amount_recommended, :request_from_date, :request_to_date, :grant_begins_from_date, :grant_begins_to_date, :grant_ends_from_date, :grant_ends_to_date, :missing_request_id, :has_been_rejected, :funding_source_ids]

      insta.derived_filters = {
          :has_been_rejected => (lambda do |search_with_attributes, request_params, name, val|
            if val == '1'
              search_with_attributes.delete :has_been_rejected
            else
              search_with_attributes[:has_been_rejected] = 0
            end
          end),

          :filter_state => (lambda do |search_with_attributes, request_params, name, val|
            states = val
            states << 'pending_secondary_pd_approval' if states.include?('pending_pd_approval')

            if states.include?('pending_secondary_pd_approval') && search_with_attributes[:program_id]
              # Have to consider that program_id may have been parsed before filter_state
              search_with_attributes[:all_request_program_ids] = search_with_attributes[:program_id]
              search_with_attributes.delete :program_id
            end
            search_with_attributes[:filter_state] = states.map{|val|val.to_crc32} if states && !states.empty?
          end),

          :program_id => (lambda do |search_with_attributes, request_params, name, val|
            program_id_strings = val
            programs = program_id_strings.map {|pid| Program.find pid rescue nil}.compact
            program_ids = programs.map do |program| 
              children = program.children_programs
              if children.empty?
                program
              else
                [program] + children
              end
            end.compact.flatten.map &:id
            # Have to consider that state may have been parsed before program_id
            if program_ids && !program_ids.empty?
              if search_with_attributes[:filter_state] && search_with_attributes[:filter_state].is_a?(Array) && search_with_attributes[:filter_state].include?('pending_secondary_pd_approval')
                search_with_attributes[:all_request_program_ids] = program_ids
              else
                search_with_attributes[:program_id] = program_ids
              end
            end
          end),
          :greater_amount_recommended => (lambda do |search_with_attributes, request_params, name, val|
            val = val.first if val && val.is_a?(Array)
            if search_with_attributes[:amount_recommended]
              search_with_attributes[:amount_recommended] = (val.to_i..(search_with_attributes[:amount_recommended].end))
            else
              search_with_attributes[:amount_recommended] = (val.to_i..999999999999)
            end
            search_with_attributes
          end),
          :lesser_amount_recommended => (lambda do |search_with_attributes, request_params, name, val|
            val = val.first if val && val.is_a?(Array)
            if search_with_attributes[:amount_recommended]
              search_with_attributes[:amount_recommended] = ((search_with_attributes[:amount_recommended].begin)..val.to_i)
            else
              search_with_attributes[:amount_recommended] = (0..val.to_i)
            end
            search_with_attributes
          end),
          :request_from_date => (lambda do |search_with_attributes, request_params, name, val|
            val = val.first if val && val.is_a?(Array)
            date_range_selector = request_params[:request][:date_range_selector] if request_params[:request]
            date_range_selector = request_params[:date_range_selector] unless date_range_selector
            case date_range_selector
            when 'funding_agreement' then
              prepare_from_date search_with_attributes, :grant_agreement_at, val
            when 'grant_begins' then
              prepare_from_date search_with_attributes, :grant_begins_at, val
            when 'grant_ends' then
              prepare_from_date search_with_attributes, :grant_ends_at, val
            end
          end),
          :request_to_date => (lambda do |search_with_attributes, request_params, name, val|
            val = val.first if val && val.is_a?(Array)
            date_range_selector = request_params[:request][:date_range_selector] if request_params[:request]
            date_range_selector = request_params[:date_range_selector] unless date_range_selector
            case date_range_selector
            when 'funding_agreement' then
              prepare_to_date search_with_attributes, :grant_agreement_at, val
            when 'grant_begins' then
              prepare_to_date search_with_attributes, :grant_begins_at, val
            when 'grant_ends' then
              prepare_to_date search_with_attributes, :grant_ends_at, val
            end
          end)
        }
      
    end
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_utc do |insta|
      insta.time_attributes = [:request_received_at, :grant_approved_at, :grant_agreement_at, :grant_amendment_at, :grant_begins_at, :grant_closed_at, :fip_projected_end_at, :ierf_start_at, :ierf_proposed_end_at, :ierf_budget_end_at] 
    end
    
    base.insta_workflow do |insta|
      insta.add_state_to_english :new, 'New Request'
      insta.add_state_to_english :pending_grant_team_approval, 'Pending Grant Team Approval'
      insta.add_state_to_english :pending_po_approval, 'Pending PO Approval'
      insta.add_state_to_english :pending_president_approval, 'Pending President Approval'
      insta.add_state_to_english :rejected, 'Rejected'
      insta.add_state_to_english :funding_recommended, 'Funding Recommended'
      insta.add_state_to_english :pending_grant_promotion, "Pending Grant/FIP Promotion"
      insta.add_state_to_english :sent_back_to_pa, 'Sent back to PA'
      insta.add_state_to_english :sent_back_to_po, 'Sent back to PO'
      insta.add_state_to_english :granted, 'Granted'
      insta.add_state_to_english :closed, 'Closed'
      insta.add_state_to_english :canceled, 'Canceled'
      
      insta.add_event_to_english :recommend_funding, 'Recommend Funding'
      insta.add_event_to_english :complete_ierf, 'Mark IERF Completed'
      insta.add_event_to_english :grant_team_approve, 'Approve'
      insta.add_event_to_english :po_approve,  'Approve'
      insta.add_event_to_english :president_approve, 'Approve'
      insta.add_event_to_english :grant_team_send_back,  'Send Back'
      insta.add_event_to_english :po_send_back, 'Send Back'
      insta.add_event_to_english :president_send_back, 'Send Back'
      insta.add_event_to_english :reject,  'Reject'
      insta.add_event_to_english :un_reject, 'Un-Reject'
      insta.add_event_to_english :become_grant, 'Promote to Grant'
      insta.add_event_to_english :close_grant, 'Close'
      insta.add_event_to_english :cancel_grant, 'Cancel'        
      
      insta.add_non_validating_event :reject
      insta.add_non_validating_event :po_send_back
      insta.add_non_validating_event :president_send_back
      insta.add_non_validating_event :grant_team_send_back
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end

    base.send :include, AASM
    base.add_aasm
    base.alias_method_chain :grantee_org_owner, :specific
    base.alias_method_chain :grantee_signatory, :specific
    base.alias_method_chain :fiscal_org_owner, :specific
    base.alias_method_chain :fiscal_signatory, :specific
    base.add_sphinx if base.respond_to?(:sphinx_indexes) && !(base.connection.adapter_name =~ /SQLite/i)

    # NOTE: for STI classes such as GrantRequest, the polymorphic associations must be replicated to get the correct class...
    base.has_many :workflow_events, :foreign_key => :workflowable_id, :conditions => ['workflowable_type in (?)', Request.request_class_names]
    base.has_many :favorites, :foreign_key => :favorable_id, :conditions => ['favorable_type in (?)', Request.request_class_names]
    base.has_many :notes, :foreign_key => :notable_id, :conditions => ['notable_type in (?)', Request.request_class_names]
    base.has_many :group_members, :foreign_key => :groupable_id, :conditions => ['groupable_type in (?)', Request.request_class_names]
  end

  module ModelClassMethods
    def request_class_names
      ['Request', 'GrantRequest', 'FipRequest']
    end
    
    def translate_delta_type granted=false
      # Note ESH: we need to not differentiate between FipRequest and GrantRequest so that they can show mixed up within the same card
      'Request' + (granted ? 'Granted' : 'NotYetGranted')
    end

    # Translate the old state to the next state that will be completed
    # Useful for the funnel
    def old_state_complete_english_translation state_name
      case state_name.to_s
      when 'new' then
        'Submitted -> Final Proposal'
      when 'funding_recommended' then
        'Final Proposal -> IERF Complete'
      when 'pending_grant_team_approval' then
        'Grants Approved'
      when 'pending_po_approval' then
        'PO Approved'
      when 'pending_svp_approval' then
        'SVP Approved'
      when 'pending_president_approval' then
        'President Approval'
      when 'pending_grant_promotion' then
        'Promoted to Grant'
      when 'granted' then
        'Closed'
      else
        state_name.to_s
      end
    end
    
    def add_aasm
      aasm_column :state
      aasm_initial_state :new

      aasm_state :new
      class_inheritable_reader :local_pre_recommended_chain
      write_inheritable_attribute :local_pre_recommended_chain, [:new]
      class_inheritable_reader :local_approval_chain
      write_inheritable_attribute :local_approval_chain, [:funding_recommended, :pending_grant_team_approval, :pending_po_approval, :pending_president_approval, :pending_grant_promotion]
      class_inheritable_reader :local_approved
      write_inheritable_attribute :local_approved, (local_approval_chain - [:pending_grant_team_approval])
      class_inheritable_reader :local_sent_back_states
      write_inheritable_attribute :local_sent_back_states, [:sent_back_to_pa, :sent_back_to_po]
      class_inheritable_reader :local_sent_back_state_mapping_to_workflow
      write_inheritable_attribute :local_sent_back_state_mapping_to_workflow, {:sent_back_to_pa => :funding_recommended, :sent_back_to_po => :pending_po_approval}
      class_inheritable_reader :local_pre_approval_states
      write_inheritable_attribute :local_pre_approval_states, [:new, :rejected]
      
      class_inheritable_reader :local_rejected_states
      write_inheritable_attribute :local_rejected_states, [:rejected]
      class_inheritable_reader :local_grant_states
      write_inheritable_attribute :local_grant_states, [:granted, :closed]
      class_inheritable_reader :local_canceled_states
      write_inheritable_attribute :local_canceled_states, [:canceled]

      class_inheritable_reader :local_promotion_events
      write_inheritable_attribute :local_promotion_events, [:recommend_funding, :complete_ierf, :grant_team_approve, :po_approve, :president_approve]
      class_inheritable_reader :local_grant_events
      write_inheritable_attribute :local_grant_events, [:become_grant, :close_grant]
      class_inheritable_reader :local_send_back_events
      write_inheritable_attribute :local_send_back_events, [:grant_team_send_back, :po_send_back, :president_send_back]
      class_inheritable_reader :local_reject_events
      write_inheritable_attribute :local_reject_events, [:reject]
      class_inheritable_reader :local_cancel_grant_events
      write_inheritable_attribute :local_cancel_grant_events, [:cancel_grant]
      class_inheritable_reader :local_un_reject_events
      write_inheritable_attribute :local_un_reject_events, [:un_reject]
      
      def self.new_states
        [:new]
      end

      def self.grant_states
        local_grant_states
      end
      
      def self.granted_state
        :granted
      end

      def self.canceled_states
        local_canceled_states
      end

      def self.pre_recommended_chain
        local_pre_recommended_chain
      end

      def self.rejected_states
        local_rejected_states
      end

      def self.approval_chain
        local_approval_chain
      end

      def self.sent_back_states
        local_sent_back_states
      end

      def self.sent_back_state_mapping_to_workflow
        local_sent_back_state_mapping_to_workflow
      end

      def self.pre_approval_states
        local_pre_approval_states
      end

      def self.promotion_events
        local_promotion_events
      end

      def self.grant_events
        local_grant_events
      end

      def self.send_back_events
        local_send_back_events
      end

      def self.cancel_grant_events
        local_cancel_grant_events
      end

      def self.reject_events
        local_reject_events
      end

      def self.un_reject_events
        local_un_reject_events
      end
      
      def self.become_grant_event
        'become_grant'
      end
      

      local_sent_back_states.each {|cur_state| aasm_state cur_state }

      aasm_state :pending_grant_team_approval
      aasm_state :pending_po_approval
      aasm_state :pending_president_approval
      aasm_state :pending_grant_promotion, :enter => :add_president_approval_date
      aasm_state :rejected
      aasm_state :funding_recommended
      aasm_state :new
      aasm_state :granted, :enter => :process_become_grant
      aasm_state :closed # Note that a user needs to close the grant.  The grants team would do this
      aasm_state :canceled # The grants team can cancel a grant after it has been granted

      aasm_event :reject do
        (Request.pre_recommended_chain + Request.approval_chain + Request.sent_back_states).each do |cur_state|
          transitions :from => cur_state, :to => :rejected unless cur_state == :rejected
        end
      end

      aasm_event :un_reject do
        transitions :from => :rejected, :to => :new
      end

      aasm_event :recommend_funding do
        transitions :from => :new, :to => :funding_recommended
      end

      aasm_event :complete_ierf do
        transitions :from => :funding_recommended, :to => :pending_grant_team_approval
        transitions :from => :sent_back_to_pa, :to => :pending_grant_team_approval, :guard => (lambda { |req| !(req.has_grant_team_ever_approved?) })
        transitions :from => :sent_back_to_pa, :to => :pending_po_approval, :guard => (lambda { |req| req.has_grant_team_ever_approved? })
      end

      aasm_event :grant_team_approve do
        transitions :from => :pending_grant_team_approval, :to => :pending_po_approval
      end

      aasm_event :grant_team_send_back do
        transitions :from => :pending_grant_team_approval, :to => :sent_back_to_pa
      end

      aasm_event :po_approve do
        transitions :from => [:pending_po_approval, :sent_back_to_po], :to => :pending_president_approval
      end

      aasm_event :po_send_back do
        transitions :from => [:pending_po_approval, :sent_back_to_po], :to => :sent_back_to_pa
      end

      aasm_event :president_approve do
        transitions :from => :pending_president_approval, :to => :pending_grant_promotion
      end

      aasm_event :president_send_back do
        transitions :from => :pending_president_approval, :to => :sent_back_to_po
      end

      aasm_event :become_grant do
        transitions :from => :pending_grant_promotion, :to => :granted
      end

      aasm_event :close_grant do
        transitions :from => :granted, :to => :closed
      end

      aasm_event :cancel_grant do
        transitions :from => :granted, :to => :canceled
      end
    end
    
    def add_sphinx
      # Note!!!: across multiple indices, the structure must be the same or the index can get corrupted and attributes, search filter will not work properly
      define_index :request_first do
        # fields
        indexes "lower(requests.fip_title)", :as => :fip_title, :sortable => true
        indexes "CONCAT(IF(type = 'FipRequest', 'F-', 'R-'),base_request_id)", :sortable => true, :as => :request_id, :sortable => true
        indexes "lower(requests.project_summary)", :as => :project_summary, :sortable => true
        indexes :id, :sortable => true
        indexes "CONCAT(IF(type = 'FipRequest', 'FG-', 'G-'),base_request_id)", :sortable => true, :as => :grant_id, :sortable => true
        indexes :type, :sortable => true
        indexes program_organization.name, :as => :program_org_name, :sortable => true
        indexes program_organization.acronym, :as => :program_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = organizations.parent_org_id)", :sortable => true, :as => :parent_program_acronym, :sortable => true
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = fiscal_organizations_requests.parent_org_id)", :sortable => true, :as => :parent_fiscal_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
        has :program_organization_id, :fiscal_organization_id
        has "if(granted = 0, (CONCAT(IFNULL(`program_organization_id`, '0'), ',', IFNULL(`fiscal_organization_id`, '0'))), null)", 
          :as => :related_request_organization_ids, :type => :multi
        has "if(granted = 1, (CONCAT(IFNULL(`program_organization_id`, '0'), ',', IFNULL(`fiscal_organization_id`, '0'))), null)", 
          :as => :related_grant_organization_ids, :type => :multi
        has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
        has "null", :as => :grant_ends_at, :type => :datetime
        has "IF(requests.state = 'rejected', 1, 0)", :as => :has_been_rejected, :type => :boolean

        has :type, :type => :string, :crc => true, :as => :filter_type
        has :state, :type => :string, :crc => true, :as => :filter_state
        has program_lead(:id), :as => :lead_user_ids

        has "null", :type => :multi, :as => :org_owner_user_ids
        has "null", :type => :multi, :as => :favorite_user_ids
        has "concat(program_lead_id, ',', IFNULL(grantee_org_owner_id, '0'), ',', IFNULL(grantee_signatory_id, '0'), ',', IFNULL(fiscal_org_owner_id, '0'), ',', IFNULL(fiscal_signatory_id, '0'))", :type => :multi, :as => :user_ids
        
        has "null", :type => :multi, :as => :raw_request_org_ids

        has "null", :type => :multi, :as => :request_org_ids
        has "null", :type => :multi, :as => :grant_org_ids
        has "null", :type => :multi, :as => :request_user_ids
        has "null", :type => :multi, :as => :funding_source_ids

        has "null", :type => :multi, :as => :group_ids

        set_property :delta => :delayed
      end

      define_index :request_second do
        indexes "lower(requests.fip_title)", :as => :fip_title, :sortable => true
        indexes 'null', :sortable => true, :as => :request_id, :sortable => true
        indexes :project_summary, :sortable => true
        indexes :id, :sortable => true
        indexes 'null', :sortable => true, :as => :grant_id, :sortable => true
        indexes :type, :sortable => true
        indexes program_organization.name, :as => :program_org_name, :sortable => true
        indexes program_organization.acronym, :as => :program_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = organizations.parent_org_id)", :sortable => true, :as => :parent_program_acronym, :sortable => true
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = fiscal_organizations_requests.parent_org_id)", :sortable => true, :as => :parent_fiscal_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
        has :program_organization_id, :fiscal_organization_id
        has "null", :as => :related_request_organization_ids, :type => :multi
        has "null", :as => :related_grant_organization_ids, :type => :multi
        has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
        has "date_add(date_add(grant_begins_at, interval duration_in_months MONTH), interval -1 DAY)", :as => :grant_ends_at, :type => :datetime
        has "IF(requests.state = 'rejected', 1, 0)", :as => :has_been_rejected, :type => :boolean

        has :type, :type => :string, :crc => true, :as => :filter_type
        has :state, :type => :string, :crc => true, :as => :filter_state
        has "null", :type => :multi, :as => :lead_user_ids

        has grantee_org_owner(:id), :as => :org_owner_user_ids
        has "null", :type => :multi, :as => :favorite_user_ids
        has "null", :type => :multi, :as => :user_ids
        has "null", :type => :multi, :as => :raw_request_org_ids

        has "null", :type => :multi, :as => :request_org_ids
        has "null", :type => :multi, :as => :grant_org_ids
        has request_users(:id), :as => :request_user_ids
        has request_funding_sources.funding_source_allocation.funding_source(:id), :as => :funding_source_ids

        has "null", :type => :multi, :as => :group_ids

        set_property :delta => :delayed
      end

      define_index :request_third do
        indexes "lower(requests.fip_title)", :as => :fip_title, :sortable => true
        indexes 'null', :sortable => true, :as => :request_id, :sortable => true
        indexes :project_summary, :sortable => true
        indexes :id, :sortable => true
        indexes 'null', :sortable => true, :as => :grant_id, :sortable => true
        indexes :type, :sortable => true
        indexes program_organization.name, :as => :program_org_name, :sortable => true
        indexes program_organization.acronym, :as => :program_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = organizations.parent_org_id)", :sortable => true, :as => :parent_program_acronym, :sortable => true
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes "(select acronym from organizations parent_org where parent_org.id = fiscal_organizations_requests.parent_org_id)", :sortable => true, :as => :parent_fiscal_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
        has :program_organization_id, :fiscal_organization_id
        has "null", :as => :related_request_organization_ids, :type => :multi
        has "null", :as => :related_grant_organization_ids, :type => :multi
        has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
        has "null", :as => :grant_ends_at, :type => :datetime
        has "IF(requests.state = 'rejected', 1, 0)", :as => :has_been_rejected, :type => :boolean

        has :type, :type => :string, :crc => true, :as => :filter_type
        has :state, :type => :string, :crc => true, :as => :filter_state
        has "null", :type => :multi, :as => :lead_user_ids

        has "null", :type => :multi, :as => :org_owner_user_ids
        has favorites.user(:id), :as => :favorite_user_ids
        has "null", :type => :multi, :as => :user_ids
        has request_organizations.organization(:id), :type => :multi, :as => :raw_request_org_ids
        has "GROUP_CONCAT(DISTINCT if(granted = 0, IFNULL(`organizations_request_organizations`.`id`, '0'), null) SEPARATOR ',')", :type => :multi, :as => :request_org_ids
        has "GROUP_CONCAT(DISTINCT if(granted = 1, IFNULL(`organizations_request_organizations`.`id`, '0'), null) SEPARATOR ',')", :type => :multi, :as => :grant_org_ids
        has "null", :type => :multi, :as => :request_user_ids
        has "null", :type => :multi, :as => :funding_source_ids

        has group_members.group(:id), :type => :multi, :as => :group_ids

        set_property :delta => :delayed
      end
    end
    
    def document_title_name
      'Request'
    end
    
    def translate_grant_type type
      case type
        when 'GrantRequest'
          'Grants'
        when 'FipRequest'
          I18n.t(:fip_name)
      end
    end
    
    # Often need to prepare a SQL condition requests.type in (GrantRequest, FipRequest), etc.  This makes it easier to do so
    def prepare_request_types_for_where_clause request_types
      request_types = [request_types] if request_types.is_a?(String)
      request_type_clause = if (request_types && request_types.is_a?(Array) && !request_types.empty?)
        quoted_rts = request_types.map{|rt| "'#{rt}'"}
        "AND requests.type in (#{quoted_rts.join(',')})"
      end || ""
    end
  end

  module ModelInstanceMethods
    def grant_ends_at
      (duration_in_months && grant_begins_at) ? (grant_begins_at + duration_in_months.month - 1.day) : grant_begins_at
    end

    def process_before_save_blocks
      if self.before_save_blocks
        self.before_save_blocks.each {|block| block.call(self)}
      end
    end

    def add_before_save_block block
      self.before_save_blocks ||= []
      self.before_save_blocks << block
    end

    # Force the sphinx indices to be updated
    def update_related_data
      if Request.respond_to? :indexed_by_sphinx?
        User.without_realtime do
          us = related_users.map(&:id)
          User.update_all 'delta = 1', ['id in (?)', us]
          unless us.empty?
            u = User.find(us.first)
            u.delta = 1
            u.save 
          end
        end
        Organization.without_realtime do
          orgs = []
          orgs << program_organization.id if program_organization
          orgs << fiscal_organization.id if fiscal_organization
          Organization.update_all 'delta = 1', ['id in (?)', orgs]
          unless orgs.empty?
            o = Organization.find(orgs.first)
            o.delta = 1
            o.save 
          end
        end
        RequestTransaction.without_realtime do
          rts = request_transactions.map(&:id)
          RequestTransaction.update_all 'delta = 1', ['id in (?)', rts]
          unless rts.empty?
            rt = RequestTransaction.find(rts.first)
            rt.delta = 1
            rt.save 
          end
        end
        RequestReport.without_realtime do
          reps = request_reports.map(&:id)
          RequestReport.update_all 'delta = 1', ['id in (?)', reps]
          unless reps.empty?
            rep = RequestReport.find(reps.first)
            rep.delta = 1
            rep.save 
          end
        end
      end
    end

    def tax_class_org
      fiscal_organization ? fiscal_organization : program_organization
    end

    def has_tax_class?
      tax_class_org ? tax_class_org.tax_class_id : nil
    end

    def is_er?
      tax_class_org ? tax_class_org.is_er? : nil
    end

    def is_grant?
      self.granted
    end

    def amount_funded
      amount_paids = request_transactions.map(&:amount_paid).compact
      amount_paids.sum if !amount_paids.empty?
    end

    def to_s
      title
    end

    def title
      "#{tax_class_org ? tax_class_org.name : ''} #{self.granted ? grant_id : request_id} #{(amount_recommended || amount_requested).to_currency(:precision => 0)}"
    end

    def allowed_to_edit?(user)
      user_roles = program.roles_for_user user
      if local_pre_approval_states.include? state.to_sym
        (Program.request_roles & user_roles).empty? # any user with a request role for this program can edit if it's in the pre approval state
      elsif false
      end
    end

    ## Letter specific helpers
    def fiscal_or_program_possessive
      if fiscal_organization && fiscal_organization != program_organization
        "#{fiscal_organization.name}'s"
      else
        'your'
      end
    end

    def proposal_date_text
      proposal_date = if ierf_proposed_end_at
        ierf_proposed_end_at.full 
      elsif request_received_at
        request_received_at.full 
      end
      "#{proposal_date} proposal and budget"
    end

    def amount_requested= new_amount
      write_attribute(:amount_requested, filter_amount(new_amount))
    end

    def amount_recommended= new_amount
      write_attribute(:amount_recommended, filter_amount(new_amount))
    end

    def generate_request_id
      current_time = Time.now
      self.update_attributes :request_received_at => current_time, 
        :base_request_id => (current_time.strftime("%y%m-") + id.to_s.rjust(5, '0'))  # Generate the request ID
    end

    def request_id
      "#{request_prefix}-#{base_request_id}" if base_request_id
    end

    def grant_id
      "#{grant_prefix}-#{base_request_id}" if self.granted && base_request_id
    end
    
    def display_id
      if granted
        grant_id
      else
        request_id
      end
    end
      
    def grant_or_request_id
      is_grant? ? grant_id : request_id
    end

    def generate_grant_dates
      self.grant_agreement_at = Time.now
      self.granted = true
      if self.ierf_start_at && self.ierf_start_at.is_a?(Time)
        self.grant_begins_at = self.ierf_start_at
      else
        self.grant_begins_at = Time.parse((grant_agreement_at + 1.month).strftime('%Y/%m/1')).next_business_day
      end
    end
    
    # This is a method meant to be run on requests that are currently in pending_secondary_pd_approval state
    # It figures out when it was switched to pending secondary approval, and if it's more than 5 days, it will promote it automatically
    def check_for_secondary_promotion
      we = workflow_events.find :first, :conditions => {:new_state => 'pending_secondary_pd_approval'}, :order => 'id desc'
      if we.created_at < (Time.now - 5.days)
        # Time to promote this puppy!!
        pending_request_programs = request_programs.select{|rp| !rp.is_approved? }
        unless pending_request_programs.empty?
          pending_request_programs.each{|rp| rp.approve}
        end
        if self.state == 'pending_secondary_pd_approval'
          self.secondary_pd_approve
        end
        self.save
      end
    end
    

    def request_prefix
      'R'
    end

    def grant_prefix
      'G'
    end

    def filter_state
      self.state
    end

    def filter_type
      self.type
    end

    def lead_user_ids
      program_lead ? program_lead.id : nil
    end

    def org_owner_user_ids
      grantee_org_owner ? grantee_org_owner.id : nil
    end
    
    def related_users
      (request_users.map{|ru| ru.user} + [program_lead, grantee_org_owner, grantee_signatory, fiscal_org_owner, fiscal_signatory]).compact.reject{|u| u.deleted_at}.sort_by{|u| [u.last_name || '', u.first_name || '']}
    end

    def related_organizations
      (request_organizations.map{|ro| ro.organization} + [program_organization, fiscal_organization]).compact.sort_by{|o| o.name || ''}.reject{|o| o.deleted_at}
    end
    
    def related_request_transactions limit_amount=20
      request_transactions.where(:deleted_at => nil).order('due_at asc').limit(limit_amount)
    end

    def related_request_reports limit_amount=20
      request_reports.where(:deleted_at => nil).order('due_at asc').limit(limit_amount)
    end
    
    def letter_project_summary
      request_project_summary = project_summary || ''
      request_project_summary = request_project_summary.strip
      request_project_summary = request_project_summary.gsub /\.$/, ''
      request_project_summary = request_project_summary.first.downcase + request_project_summary[1..request_project_summary.size]
    end

    def letter_project_summary_without_leading_to
      request_project_summary = letter_project_summary || ''
      request_project_summary.gsub /^To/i, ''
    end

    # Find out all the states a request of this type can pass through from the time it is new doing normal promotion
    def event_timeline
      old_state = self.state
      self.state = 'new'
      timeline = Request.suspended_delta(false)  do
        working_timeline = [self.state]
        while cur_event = (self.aasm_events_for_current_state & (Request.promotion_events + Request.grant_events)).last
          self.force_all_request_programs_approved = true if cur_event == :secondary_pd_approve
          self.send cur_event
          working_timeline << self.state
        end
        working_timeline
      end || []
      self.state = old_state
      timeline
    end

    # Make the delta type 
    def realtime_classname
      Request.translate_delta_type self.granted
    end
    
    def add_president_approval_date
      self.grant_approved_at = Time.now
    end

    def process_become_grant
      self.granted = true
    end

    def has_grant_team_ever_approved?
      !(workflow_events.select do |event| 
        (event.old_state == 'pending_grant_team_approval' && event.new_state == 'pending_po_approval')
      end.empty?)
    end
    
    def grantee_org_owner_with_specific
      if program_organization
        grantee_org_owner_without_specific
      end
    end
    def grantee_signatory_with_specific
      if program_organization
        grantee_signatory_without_specific
      end
    end
    def fiscal_org_owner_with_specific
      if fiscal_organization
        fiscal_org_owner_without_specific
      end
    end
    def fiscal_signatory_with_specific
      if fiscal_organization
        fiscal_signatory_without_specific
      end
    end
    
    def state_after_pre_recommended_chain
      state && !((Request.pre_recommended_chain + Request.rejected_states).include?(state.to_sym))
    end
    
    def signatory_contact
      fiscal_signatory  || fiscal_org_owner || grantee_signatory ||  grantee_org_owner || User.new
    end
    
    def signatory_user_org
      return nil if signatory_contact.nil? || address_org.nil?
      signatory_contact.user_organizations.where(:organization_id => address_org.id).first
    end
    
    def signatory_user_org_title
      signatory_user_org ? signatory_user_org.title : nil
    end  
    
    def address_org
      fiscal_organization || program_organization || Organization.new
    end
    
    def all_request_programs_approved? program=nil
      return force_all_request_programs_approved if force_all_request_programs_approved # for event_timeline purposes
      checking_programs = request_programs.reject{|rp| rp.program == program}
      result = checking_programs.select {|rp| rp.state != 'approved'}.empty?
      result
    end
    
    # Mark related classes that show up in searches as deleted
    def handle_cascading_deletes
      if self.deleted_at
        user = User.find(updated_by_id) if updated_by_id
        request_reports.each {|rep| rep.safe_delete(user)}
        request_transactions.each {|trans| trans.safe_delete(user)}
      end
    end
  end
end
