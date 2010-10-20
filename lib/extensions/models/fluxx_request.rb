module FluxxRequest
  SEARCH_ATTRIBUTES = [:program_id, :initiative_id, :created_by_id, :filter_state, :program_organization_id, :fiscal_organization_id, :favorite_user_ids, :lead_user_ids, :org_owner_user_ids, :granted, :filter_type]
  FAR_IN_THE_FUTURE = Time.now + 1000.year
  begin FAR_IN_THE_FUTURE.to_i rescue FAR_IN_THE_FUTURE = Time.now + 10.year end

  def self.included(base)
    base.belongs_to :program_organization, :class_name => 'Organization', :foreign_key => :program_organization_id
    base.send :attr_accessor, :program_organization_lookup
    base.belongs_to :fiscal_organization, :class_name => 'Organization', :foreign_key => :fiscal_organization_id
    base.send :attr_accessor, :fiscal_organization_lookup
    base.has_many :request_geo_states
    base.has_many :request_organizations
    base.has_many :request_users
    base.has_many :geo_states, :through => :request_geo_states
    base.has_many :request_transactions
    base.accepts_nested_attributes_for :request_transactions, :allow_destroy => true
    base.has_many :request_funding_sources
    base.has_many :request_letters
    base.has_one :grant_approved_event, :class_name => 'WorkflowEvent', :conditions => {:workflowable_type => base.name, :new_state => 'granted'}, :foreign_key => :workflowable_id
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})

    base.belongs_to :program
    base.belongs_to :initiative
    base.after_create :generate_request_id
    base.after_save :process_before_save_blocks
    base.before_save :resolve_letter_type_changes
    
    # base.after_commit :update_related_data
    base.send :attr_accessor, :before_save_blocks

    base.send :attr_accessor, :grant_agreement_letter_type
    base.send :attr_accessor, :award_letter_type
    base.send :attr_accessor, :force_all_request_programs_approved

    base.has_many :request_reports, :conditions => 'request_reports.deleted_at IS NULL'
    base.has_many :letter_request_reports, :class_name => 'RequestReport', :foreign_key => :request_id, :conditions => "request_reports.deleted_at IS NULL AND request_reports.report_type <> 'Eval'"
    base.accepts_nested_attributes_for :request_reports, :allow_destroy => true
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
            'Lead PO/PD', 'Program', 'Initiative', ['Date Request Received', :date], ['Duration', :integer], 
            'Geo Focus (States)', 'Constituents', 'Means', 'Type of Org', 'Funding Source', ['Date Created', :date], ['Date Last Updated', :date], 'Request Summary']
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
          program.name, initiative.name,
          requests.request_received_at, 
          requests.duration_in_months,
          (select replace(group_concat(name, ', '), ', ', '') from geo_states, request_geo_states where geo_states.id = request_geo_states.geo_state_id
           and request_geo_states.request_id = requests.id group by request_geo_states.request_id) geo_states, 
          (select replace(group_concat(mev.value, ', '), ', ', '')
          from multi_element_values mev, multi_element_groups meg, multi_element_choices mec
          WHERE   meg.name = 'constituents'
          and multi_element_group_id = meg.id
          and multi_element_value_id = mev.id
          and target_id = requests.id
          group by requests.id) constituents,
          (select replace(group_concat(mev.value, ', '), ', ', '')
          from multi_element_values mev, multi_element_groups meg, multi_element_choices mec
          WHERE   (meg.name = 'usa_means' OR meg.name = 'china_means')
          and multi_element_group_id = meg.id
          and multi_element_value_id = mev.id
          and target_id = requests.id
          group by requests.id) means,
          (select mev_tax_class.value from
           multi_element_groups meg_tax_class,
           multi_element_values mev_tax_class 
           WHERE meg_tax_class.name = 'tax_classes' and
           multi_element_group_id = meg_tax_class.id and program_organization.tax_class_id = mev_tax_class.id) org_tax_class,
          replace(group_concat(funding_sources.name, ', '), ', ', '') funding_source_name,
          requests.created_at, requests.updated_at, 
          project_summary
                         FROM requests
                         LEFT OUTER JOIN programs program ON program.id = requests.program_id
                         LEFT OUTER JOIN initiatives initiative ON initiative.id = requests.initiative_id
                         LEFT OUTER JOIN organizations program_organization ON program_organization.id = requests.program_organization_id
                         LEFT OUTER JOIN organizations fiscal_organization ON fiscal_organization.id = requests.fiscal_organization_id
                         LEFT OUTER JOIN request_funding_sources ON request_funding_sources.request_id = requests.id
                         LEFT OUTER JOIN funding_sources ON funding_sources.id = request_funding_sources.funding_source_id
                         left outer join geo_states as program_org_country_states on program_org_country_states.id = program_organization.geo_state_id
                         left outer join geo_countries as program_org_countries on program_org_countries.id = program_organization.geo_country_id
                         left outer join geo_states as fiscal_org_country_states on fiscal_org_country_states.id = fiscal_organization.geo_state_id
                         left outer join geo_countries as fiscal_org_countries on fiscal_org_countries.id = fiscal_organization.geo_country_id
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
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES + [:group_ids, :greater_amount_recommended, :lesser_amount_recommended, :request_from_date, :request_to_date, :grant_begins_from_date, :grant_begins_to_date, :grant_ends_from_date, :grant_ends_to_date, :missing_request_id, :has_been_rejected, :funding_source_ids]

      insta.derived_filters = {
          :has_been_rejected => (lambda do |search_with_attributes, name, val|
            if val == '1'
              search_with_attributes.delete :has_been_rejected
            else
              search_with_attributes[:has_been_rejected] = 0
            end
          end),

          :filter_state => (lambda do |search_with_attributes, name, val|
            states = val
            states << 'pending_secondary_pd_approval' if states.include?('pending_pd_approval')

            if states.include?('pending_secondary_pd_approval') && search_with_attributes[:program_id]
              # Have to consider that program_id may have been parsed before filter_state
              search_with_attributes[:all_request_program_ids] = search_with_attributes[:program_id]
              search_with_attributes.delete :program_id
            end
            search_with_attributes[:filter_state] = states.map{|val|val.to_crc32} if states && !states.empty?
          end),

          :program_id => (lambda do |search_with_attributes, name, val|
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
          :greater_amount_recommended => (lambda do |search_with_attributes, name, val|
            if search_with_attributes[:amount_recommended]
              search_with_attributes[:amount_recommended] = (val.to_i..(search_with_attributes[:amount_recommended].end))
            else
              search_with_attributes[:amount_recommended] = (val.to_i..999999999999)
            end
            search_with_attributes
          end),
          :lesser_amount_recommended => (lambda do |search_with_attributes, name, val|
            if search_with_attributes[:amount_recommended]
              search_with_attributes[:amount_recommended] = ((search_with_attributes[:amount_recommended].begin)..val.to_i)
            else
              search_with_attributes[:amount_recommended] = (0..val.to_i)
            end
            search_with_attributes
          end),
          :request_from_date => (lambda do |search_with_attributes, name, val|
            case search_with_attributes[:date_range_selector]
            when 'funding_agreement' then
              prepare_from_date search_with_attributes, val, :grant_agreement_at
            when 'grant_begins' then
              prepare_from_date search_with_attributes, val, :grant_begins_at
            when 'grant_ends' then
              prepare_from_date search_with_attributes, val, :grant_ends_at
            end
          end),
          :request_to_date => (lambda do |search_with_attributes, name, val|
            case search_with_attributes[:date_range_selector]
            when 'funding_agreement' then
              prepare_to_date search_with_attributes, val, :grant_agreement_at
            when 'grant_begins' then
              prepare_to_date search_with_attributes, val, :grant_begins_at
            when 'grant_ends' then
              prepare_to_date search_with_attributes, val, :grant_ends_at
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
      insta.states_to_english = {:new => 'New Request',
        :pending_grant_team_approval => 'Pending Grant Team Approval',
        :pending_po_approval => 'Pending PO Approval',
        :pending_president_approval => 'Pending President Approval',
        :rejected => 'Rejected',
        :funding_recommended => 'Funding Recommended',
        :pending_grant_promotion => 'Pending Grant/FIP Promotion',
        :sent_back_to_pa => 'Sent back to PA',
        :sent_back_to_po => 'Sent back to PO',
        :granted => 'Granted',
        :closed => 'Closed',
        :canceled => 'Canceled'}
      
      insta.events_to_english = {:recommend_funding => 'Recommend Funding',
        :complete_ierf => 'Mark IERF Completed',
        :grant_team_approve => 'Approve',
        :po_approve =>  'Approve',
        :president_approve => 'Approve',
        :grant_team_send_back =>  'Send Back',
        :po_send_back => 'Send Back',
        :president_send_back => 'Send Back',
        :reject =>  'Reject',
        :un_reject => 'Un-Reject',
        :become_grant => 'Promote to Grant',
        :close_grant => 'Close',
        :cancel_grant => 'Cancel'}
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
      write_inheritable_attribute :local_pre_recommended_chain, [:new, :funding_recommended, :unknown_from_import]
      class_inheritable_reader :local_approval_chain
      write_inheritable_attribute :local_approval_chain, [:pending_grant_team_approval, :pending_po_approval, :pending_president_approval, :pending_grant_promotion]
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
        [:new, :unknown_from_import]
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
      aasm_state :unknown_from_import
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
        transitions :from => :unknown_from_import, :to => :funding_recommended
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
      p "ESH: adding sphinx index definition"
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
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :initiative_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
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
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :initiative_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
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
        has request_funding_sources.funding_source(:id), :as => :funding_source_ids

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
        indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
        indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
        indexes program.name, :as => :program_name, :sortable => true

        # attributes
        has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :initiative_id, :request_received_at, :grant_agreement_at, :grant_begins_at, :amount_requested, :amount_recommended, :granted
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
    
    def prepare_from_date search_with_attributes, name, val
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
    
    def prepare_to_date search_with_attributes, name, val
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

    def request_prefix
      'R'
    end

    def grant_prefix
      'G'
    end

    def grant_agreement_request_letter
      request_letters.reload.select {|rl| rl.letter_template && (rl.letter_template.category == LetterTemplate.grant_agreement_category)}.first
    end

    def load_grant_agreement_letter_type
      ga_letter = grant_agreement_request_letter
      ga_letter.letter_template.id if ga_letter && ga_letter.letter_template
    end

    def award_request_letter
      request_letters.reload.select {|rl| rl.letter_template && (rl.letter_template.category == LetterTemplate.award_category)}.first
    end

    def load_award_letter_type
      al_letter = award_request_letter
      al_letter.letter_template.id if al_letter && al_letter.letter_template
    end
    
    def resolve_letter_type_changes
      ga_request_letter = grant_agreement_request_letter
      if !@grant_agreement_letter_type.blank? && ((load_grant_agreement_letter_type && @grant_agreement_letter_type != load_grant_agreement_letter_type) || !load_grant_agreement_letter_type)
        ga_letter_template = LetterTemplate.find(@grant_agreement_letter_type)
        if ga_request_letter
          # Need to swap out the existing content and point to the new letter_template
          ga_request_letter.letter_template = ga_letter_template
          ga_request_letter.letter = ga_letter_template.letter
          ga_request_letter.save
        else
          # No GA request letter exists yet- let's create one
          RequestLetter.create :request => self, :letter_template => ga_letter_template, :letter => ga_letter_template.letter
        end
      end

      awd_request_letter = award_request_letter
      if !@award_letter_type.blank? && ((load_award_letter_type && @award_letter_type != load_award_letter_type) || !load_award_letter_type)
        award_letter_template = LetterTemplate.find(@award_letter_type)
        if awd_request_letter
          # Need to swap out the existing content and point to the new letter_template
          awd_request_letter.letter_template = award_letter_template
          awd_request_letter.letter = award_letter_template.letter
          awd_request_letter.save
        else
          # No GA request letter exists yet- let's create one
          RequestLetter.create :request => self, :letter_template => award_letter_template, :letter => award_letter_template.letter
        end
      end
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
      !((Request.pre_recommended_chain + Request.rejected_states).include?(state.to_sym))
    end
  end
end
