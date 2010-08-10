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
    base.has_many :request_letters
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
    
    # NOTE: for STI classes such as GrantRequest, the polymorphic associations must be replicated to get the correct class...
    base.has_many :workflow_events, :foreign_key => :workflowable_id, :conditions => {:workflowable_type => base.name}
    base.has_many :favorites, :foreign_key => :favorable_id, :conditions => {:favorable_type => base.name}
    base.has_many :notes, :foreign_key => :notable_id, :conditions => {:notable_type => base.name}
    base.has_many :group_members, :foreign_key => :groupable_id, :conditions => {:groupable_type => base.name}

    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:request_received_at, :grant_approved_at, :grant_agreement_at, :grant_amendment_at, :grant_begins_at, :grant_closed_at, :fip_projected_end_at, :ierf_start_at, :ierf_proposed_end_at, :ierf_budget_end_at] 
    end
    
    base.insta_workflow do |insta|
      insta.states_to_english = {:actually_due => 'Actually Due',:tentatively_due => 'Tentatively Due', :paid => 'Paid', :new => 'New'}
      insta.events_to_english = {:mark_actually_due => 'Mark Due', :mark_paid => 'Pay'}
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
  end

  module ModelClassMethods
    def state_to_english
      Request.state_to_english_translation state
    end

    def self.state_to_english_translation state_name
      case state_name.to_s
      when 'new':
        'New Request'
      when 'pending_grant_team_approval':
        'Pending Grant Team Approval'
      when 'small_complete_ierf':
        'Pending SVP Approval'
      when 'pending_po_approval':
        'Pending PO Approval'
      when 'pending_president_approval':
        'Pending President Approval'
      when 'rejected':
        'Rejected'
      when 'funding_recommended':
        'Funding Recommended'
      when 'pending_grant_promotion':
        'Pending Grant/FIP Promotion'
      when 'sent_back_to_pa':
        'Sent back to PA'
      when 'sent_back_to_po':
        'Sent back to PO'
      when 'granted':
        'Granted'
      when 'closed':
        'Closed'
      when 'canceled':
        'Canceled'
      when 'unknown_from_import':
        'Unknown from Import'
      else
        state_name.to_s
      end
    end

    # Translate the old state to the next state that will be completed
    # Useful for the funnel
    def self.old_state_complete_english_translation state_name
      case state_name.to_s
      when 'new':
        'Submitted -> Final Proposal'
      when 'funding_recommended':
        'Final Proposal -> IERF Complete'
      when 'pending_grant_team_approval':
        'Grants Approved'
      when 'pending_po_approval':
        'PO Approved'
      when 'pending_svp_approval':
        'SVP Approved'
      when 'pending_president_approval':
        'President Approval'
      when 'pending_grant_promotion':
        'Promoted to Grant'
      when 'granted':
        'Closed'
      else
        state_name.to_s
      end
    end


    def self.event_to_english_translation event_name
      case event_name.to_s
      when 'recommend_funding':
        'Recommend Funding'
      when 'complete_ierf':
        'Mark IERF Completed'
      when 'grant_team_approve':
        'Approve'
      when 'po_approve':
        'Approve'
      when 'president_approve':
        'Approve'
      when 'grant_team_send_back':
        'Send Back'
      when 'po_send_back':
        'Send Back'
      when 'president_send_back':
        'Send Back'
      when 'reject':
        'Reject'
      when 'un_reject':
        'Un-Reject'
      when 'become_grant':
        'Promote to Grant'
      when 'close_grant':
        'Close'
      when 'cancel_grant':
        'Cancel'
      else
        event_name.to_s
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
      

      local_sent_back_states.each {|cur_state| aasm_state cur_state }

      aasm_state :pending_grant_team_approval
      aasm_state :pending_po_approval
      aasm_state :pending_president_approval
      aasm_state :pending_grant_promotion, :enter => :add_president_approval_date
      aasm_state :unknown_from_import
      aasm_state :rejected
      aasm_state :funding_recommended
      aasm_state :new
      aasm_state :granted
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
        # TODO ESH: fix roles
        # user_ids = roles.map do |role| 
        #   role.roles_users.map do |ru| 
        #     ru.user.id
        #   end
        # end.compact.flatten
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

    def add_president_approval_date
      self.grant_approved_at = Time.now
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
