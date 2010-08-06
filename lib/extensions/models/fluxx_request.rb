module FluxxRequest
  def self.included(base)
    # specify_utc_time_attributes [:request_received_at, :grant_approved_at, :grant_agreement_at, :grant_amendment_at, :grant_begins_at, :grant_closed_at, :fip_projected_end_at, :ierf_start_at, :ierf_proposed_end_at, :ierf_budget_end_at] 
    base.belongs_to :program_organization, :class_name => 'Organization', :foreign_key => :program_organization_id
    base.belongs_to :fiscal_organization, :class_name => 'Organization', :foreign_key => :fiscal_organization_id
    base.has_many :request_geo_states
    base.has_many :request_organizations
    base.has_many :request_users
    base.has_many :geo_states, :through => :request_geo_states
    base.has_many :request_transactions
    base.accepts_nested_attributes_for :request_transactions, :allow_destroy => true
    base.has_many :request_funding_sources
    base.has_many :roles_users, :through => :roles
    base.has_many :request_letters
    base.has_many :workflow_events, :as => :workflowable
    base.has_one :grant_approved_event, :class_name => 'WorkflowEvent', :conditions => {:workflowable_type => base.name, :new_state => 'granted'}, :foreign_key => :workflowable_id

    base.belongs_to :program
    base.belongs_to :initiative
    base.after_create :generate_request_id
    base.after_save :process_before_save_blocks
    base.before_save :resolve_letter_type_changes
    base.after_commit :update_related_data
    base.before_save :track_workflow_changes
    base.send :attr_accessor, :before_save_blocks

    base.send :attr_accessor, :grant_agreement_letter_type
    base.send :attr_accessor, :award_letter_type
    base.send :attr_accessor, :force_all_request_programs_approved

    base.has_many :request_documents, :conditions => 'request_documents.deleted_at IS NULL'
    base.has_many :request_reports, :conditions => 'request_reports.deleted_at IS NULL'
    base.has_many :letter_request_reports, :class_name => 'RequestReport', :foreign_key => :request_id, :conditions => "request_reports.deleted_at IS NULL AND request_reports.report_type <> 'Eval'"
    base.accepts_nested_attributes_for :request_reports, :allow_destroy => true
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'

    # Note!!!: across multiple indices, the structure must be the same or the index can get corrupted and attributes, search filter will not work properly
    base.define_index :request_first do
      # fields
      indexes :fip_title
      indexes "CONCAT(IF(type = 'FipRequest', 'F-', 'R-'),base_request_id)", :sortable => true, :as => :request_id, :sortable => true
      indexes :project_summary, :sortable => true
      indexes :id, :sortable => true
      indexes "CONCAT(IF(type = 'FipRequest', 'FG-', 'G-'),base_request_id)", :sortable => true, :as => :grant_id, :sortable => true
      indexes :type, :sortable => true
      indexes program_organization.name, :as => :program_org_name, :sortable => true
      indexes program_organization.acronym, :as => :program_org_acronym, :sortable => true
      indexes fiscal_organization.name, :as => :fiscal_org_name, :sortable => true
      indexes fiscal_organization.acronym, :as => :fiscal_org_acronym, :sortable => true
      indexes program.name, :as => :program_name, :sortable => true
    
      # attributes
      has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :amount_requested, :amount_recommended, :granted
      has :program_organization_id, :fiscal_organization_id
      has "if(granted = 0, (CONCAT(IFNULL(`program_organization_id`, '0'), ',', IFNULL(`fiscal_organization_id`, '0'))), null)", 
        :as => :related_request_organization_ids, :type => :multi
      has "if(granted = 1, (CONCAT(IFNULL(`program_organization_id`, '0'), ',', IFNULL(`fiscal_organization_id`, '0'))), null)", 
        :as => :related_grant_organization_ids, :type => :multi
      has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
      has "IF(requests.state = 'rejected', 1, 0)", :as => :has_been_rejected, :type => :boolean
    
      has :type, :type => :string, :crc => true, :as => :filter_type
      has :state, :type => :string, :crc => true, :as => :filter_state
      has lead_user_roles.roles_users.user(:id), :as => :lead_user_ids

      has "null", :type => :multi, :as => :org_owner_user_ids
      has "null", :type => :multi, :as => :favorite_user_ids
      has roles.roles_users.user(:id), :as => :user_ids
      has "null", :type => :multi, :as => :raw_request_org_ids
    
      has "null", :type => :multi, :as => :request_org_ids
      has "null", :type => :multi, :as => :grant_org_ids
      has "null", :type => :multi, :as => :request_user_ids
      has "null", :type => :multi, :as => :funding_source_ids

      has "null", :type => :multi, :as => :all_request_program_ids
      has "null", :type => :multi, :as => :un_approved_request_program_ids
      has "null", :type => :multi, :as => :group_ids

      set_property :delta => true
    end

    base.define_index :request_second do
      indexes :fip_title
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
      has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :amount_requested, :amount_recommended, :granted
      has :program_organization_id, :fiscal_organization_id
      has "null", :as => :related_request_organization_ids, :type => :multi
      has "null", :as => :related_grant_organization_ids, :type => :multi
      has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
      has "IF(requests.state = 'rejected', 1, 0)", :as => :has_been_rejected, :type => :boolean

      has :type, :type => :string, :crc => true, :as => :filter_type
      has :state, :type => :string, :crc => true, :as => :filter_state
      has "null", :type => :multi, :as => :lead_user_ids

      has grantee_owner_roles.roles_users.user(:id), :as => :org_owner_user_ids
      has "null", :type => :multi, :as => :favorite_user_ids
      has "null", :type => :multi, :as => :user_ids
      has "null", :type => :multi, :as => :raw_request_org_ids
    
      has "null", :type => :multi, :as => :request_org_ids
      has "null", :type => :multi, :as => :grant_org_ids
      has request_users.user(:id), :as => :request_user_ids
      has request_funding_sources.funding_source(:id), :as => :funding_source_ids
    
      has "CONCAT(requests.program_id, CONCAT(',', GROUP_CONCAT(DISTINCT IFNULL(`request_programs`.`program_id`, '0') SEPARATOR ',')))", :type => :multi, :as => :all_request_program_ids
      has un_approved_request_programs.program_id, :as => :un_approved_request_program_ids
      has "null", :type => :multi, :as => :group_ids

      set_property :delta => true
    end

    base.define_index :request_third do
      indexes :fip_title
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
      has :created_at, :updated_at, :deleted_at, :created_by_id, :program_id, :sub_program_id, :request_received_at, :grant_agreement_at, :amount_requested, :amount_recommended, :granted
      has :program_organization_id, :fiscal_organization_id
      has "null", :as => :related_request_organization_ids, :type => :multi
      has "null", :as => :related_grant_organization_ids, :type => :multi
      has "IF(requests.base_request_id IS NULL, 1, 0)", :as => :missing_request_id, :type => :boolean
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

      has "null", :type => :multi, :as => :all_request_program_ids
      has "null", :type => :multi, :as => :un_approved_request_program_ids
      has group_members.group(:id), :type => :multi, :as => :group_ids

      set_property :delta => true
    end

    base.has_many :favorites, :as => :favorable
    base.has_many :notes, :as => :notable
    base.has_many :group_members, :as => :groupable

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def translate_delta_type granted=false
      # Note ESH: we need to not differentiate between FipRequest and GrantRequest so that they can show mixed up within the same card
      'Request' + (granted ? 'Granted' : 'NotYetGranted')
    end
  end

  module ModelInstanceMethods
    def grant_ends_at
      duration_in_months ? (grant_begins_at + duration_in_months.month - 1.day) : grant_begins_at
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
      Request.index_delta
      User.without_delta do
        user_ids = roles.map do |role| 
          role.roles_users.map do |ru| 
            ru.user.id
          end
        end.compact.flatten
        User.update_all 'delta = 1', ['id in (?)', user_ids]
        User.index_delta
      end
      Organization.without_delta do
        orgs = []
        orgs << program_organization.id if program_organization
        orgs << fiscal_organization.id if fiscal_organization
        Organization.update_all 'delta = 1', ['id in (?)', orgs]
        Organization.index_delta
      end
      RequestTransaction.without_delta do
        RequestTransaction.update_all 'delta = 1', ['id in (?)', request_transactions.map(&:id)]
        RequestTransaction.index_delta
      end
      RequestReport.without_delta do
        RequestReport.update_all 'delta = 1', ['id in (?)', request_reports.map(&:id)]
        RequestReport.index_delta
      end
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
      if PRE_APPROVAL_STATES.include? state.to_sym
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

    def old_amount_funded= new_amount
      write_attribute(:old_amount_funded, filter_amount(new_amount))
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
      request_letters.select {|rl| rl.letter_template && (rl.letter_template.category == LetterTemplate.grant_agreement_category)}.first
    end

    def grant_agreement_letter_type
      ga_letter = grant_agreement_request_letter
      ga_letter.letter_template.id if ga_letter && ga_letter.letter_template
    end

    def award_request_letter
      request_letters.select {|rl| rl.letter_template && (rl.letter_template.category == LetterTemplate.award_category)}.first
    end

    def award_letter_type
      al_letter = award_request_letter
      al_letter.letter_template.id if al_letter && al_letter.letter_template
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
    def delta_type
      Request.translate_delta_type self.granted
    end

  end
end