module FluxxRequestTransaction
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :grant, :class_name => 'GrantRequest', :foreign_key => 'request_id', :conditions => {:granted => 1}
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :payment_recorded_by, :class_name => 'User', :foreign_key => 'payment_recorded_by_id'
    base.has_many :workflow_events, :as => :workflowable
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta], :protect => true})
    base.send :include, AASM

    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at, :paid_at, :transaction_at] 
    end
    
    base.insta_workflow do |insta|
      insta.states_to_english = {:actually_due => 'Actually Due',:tentatively_due => 'Tentatively Due', :paid => 'Paid', :new => 'New'}
      insta.events_to_english = {:mark_actually_due => 'Mark Due', :mark_paid => 'Pay'}
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
    base.add_aasm
  end

  module ModelClassMethods
    def add_aasm
      aasm_column :state
      aasm_initial_state :tentatively_due

      aasm_state :new
      aasm_state :tentatively_due
      aasm_state :actually_due, :enter => :adjust_due_date
      aasm_state :paid
      aasm_event :mark_actually_due do
        transitions :from => :new, :to => :actually_due
        transitions :from => :tentatively_due, :to => :actually_due
      end

      aasm_event :mark_paid do
        transitions :from => :new, :to => :paid
        transitions :from => :tentatively_due, :to => :paid
        transitions :from => :actually_due, :to => :paid
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