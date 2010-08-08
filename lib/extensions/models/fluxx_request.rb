module FluxxRequest
  def self.included(base)
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
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

    base.belongs_to :program
    base.belongs_to :initiative
    base.after_create :generate_request_id
    base.after_save :process_before_save_blocks
    base.after_commit :update_related_data
    base.send :attr_accessor, :before_save_blocks

    base.send :attr_accessor, :grant_agreement_letter_type
    base.send :attr_accessor, :award_letter_type
    base.send :attr_accessor, :force_all_request_programs_approved

    base.has_many :request_documents, :conditions => 'request_documents.deleted_at IS NULL'
    base.has_many :request_reports, :conditions => 'request_reports.deleted_at IS NULL'
    base.has_many :letter_request_reports, :class_name => 'RequestReport', :foreign_key => :request_id, :conditions => "request_reports.deleted_at IS NULL AND request_reports.report_type <> 'Eval'"
    base.accepts_nested_attributes_for :request_reports, :allow_destroy => true
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

    base.has_many :favorites, :as => :favorable
    base.has_many :notes, :as => :notable
    base.has_many :group_members, :as => :groupable

    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:request_received_at, :grant_approved_at, :grant_agreement_at, :grant_amendment_at, :grant_begins_at, :grant_closed_at, :fip_projected_end_at, :ierf_start_at, :ierf_proposed_end_at, :ierf_budget_end_at] 
    end
    
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

# 
# 1. What program roles should we include with grant_ri?  President/PA/etc... 
    # I’m thinking the RI should include the same roles as EF, minus the Program Director and SVP. 
    # From what I’ve seen, the PD and SVP are an extra level of hierarchy that most grantmakers don’t have. 
    # That being said, what’s the easiest – adding PD for groups who do have one, or removing for groups who don’t?
# 2. What should we populate in the new request form for:
#   - primary contact: guessing this should be anybody from the primary/fiscal org Yes, correct.
#   - primary signatory: do we want this? Yes, I’ve heard from others that this is often the case with grantees even outside EF. 
#     People have remarked during demo’s that they like this feature.
#   - program officer: which role/s should we use here?  Keep it the way we do now where program officer or higher program role for 
#     the current program or rollup program? Yup, same way works well.
# 3. What request workflow should we include with fluxx-oss for Grants/FIPS? (I’m wondering if we should just ditch FIPs for the RI, 
#    and keep things simple to start – again, it depends on whether it’s easier to add or subtract during implementation. 
#    Here’s the flow I think we should go with:
# 
# PA > PO > President > Grant Promotion > Granted > Closed
