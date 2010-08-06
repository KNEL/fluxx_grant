module FluxxRequestTransaction
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :grant, :class_name => 'GrantRequest', :foreign_key => 'request_id', :conditions => {:granted => 1}
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :modified_by, :class_name => 'User', :foreign_key => 'modified_by_id'
    base.belongs_to :payment_recorded_by, :class_name => 'User', :foreign_key => 'payment_recorded_by_id'
    base.has_many :workflow_events, :as => :workflowable
    base.before_save :track_workflow_changes
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta], :protect => true})
    base.send :include, AASM
    #base.specify_utc_time_attributes [:due_at, :paid_at, :transaction_at] 

    base.aasm_column :state
    base.aasm_initial_state :tentatively_due

    base.aasm_state :new
    base.aasm_state :tentatively_due
    base.aasm_state :actually_due, :enter => :adjust_due_date
    base.aasm_state :paid
    base.aasm_event :mark_actually_due do
      transitions :from => :new, :to => :actually_due
      transitions :from => :tentatively_due, :to => :actually_due
    end

    base.aasm_event :mark_paid do
      transitions :from => :new, :to => :paid
      transitions :from => :tentatively_due, :to => :paid
      transitions :from => :actually_due, :to => :paid
    end

    base.define_index do
      # fields
      indexes request.program_organization.name, :as => :request_org_name, :sortable => true
      indexes request.program_organization.acronym, :as => :request_org_acronym, :sortable => true
      indexes "if(requests.type = 'FipRequest', concat('FG-',requests.base_request_id), concat('G-',requests.base_request_id))", :as => :request_grant_id, :sortable => true

      # attributes
      has created_at, updated_at, deleted_at, due_at, paid_at, amount_paid, amount_due
      set_property :delta => true
      has :state, :type => :string, :crc => true, :as => :filter_state
      has grant.state, :type => :string, :crc => true, :as => :grant_state
      has grant(:id), :as => :grant_ids
      has grant.program(:id), :as => :grant_program_ids
      has grant.sub_program(:id), :as => :grant_sub_program_ids
      has request(:type), :type => :string, :crc => true, :as => :request_type
      has "IF(request_transactions.state = 'paid' OR (paid_at IS NOT NULL AND amount_paid IS NOT NULL), 1, 0)", :as => :has_been_paid, :type => :boolean
      has "CONCAT(IFNULL(`requests`.`program_organization_id`, '0'), ',', IFNULL(`requests`.`fiscal_organization_id`, '0'))", :as => :related_organization_ids, :type => :multi
      has request.lead_user_roles.roles_users.user(:id), :as => :lead_user_ids
      has group_members.group(:id), :type => :multi, :as => :group_ids
      has favorites.user(:id), :as => :favorite_user_ids
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def state_names
      [:new, :tentatively_due, :actually_due, :paid]
    end

    def state_to_english_translation state_name
      case state_name.to_s
      when 'actually_due':
        'Actually Due'
      when 'tentatively_due':
        'Tentatively Due'
      when 'paid':
        'Paid'
      when 'new':
        'New'
      else
        state_name.to_s
      end
    end
  end

  module ModelInstanceMethods
    def state_to_english
      RequestTransaction.state_to_english_translation state
    end

    def adjust_due_date
      self.due_at = Time.now
    end
    def has_been_paid
      state == 'paid' || (paid_at && amount_paid)
    end

    def title
      "Request Transaction of #{amount_due.to_currency :precision => 0} for #{request.grant_id}" if amount_due && request
    end

    def filter_state
      self.state
    end

    def request_type
      request.type if request
    end

    def grant_program_ids
      if request.program
        [request.program.id]
      else
        []
      end
    end

    def grant_sub_program_ids
      if request.sub_program
        [request.sub_program.id]
      else
        []
      end
    end

    def amount_paid= new_amount
      write_attribute(:amount_paid, filter_amount(new_amount))
    end

    def amount_due= new_amount
      write_attribute(:amount_due, filter_amount(new_amount))
    end
  end
end