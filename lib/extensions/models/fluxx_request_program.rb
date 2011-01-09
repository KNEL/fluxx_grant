module FluxxRequestProgram
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id]
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :request
    base.belongs_to :program
    base.has_many :workflow_events, :as => :workflowable

    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {}
    end

    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_multi
    base.insta_export do |insta|
      insta.filename = 'request_program'
      insta.headers = [['Date Created', :date], ['Date Updated', :date]]
      insta.sql_query = "select created_at, updated_at
                from request_programs
                where id IN (?)"
    end
    base.insta_lock

    base.insta_template do |insta|
      insta.entity_name = 'request_program'
      insta.add_methods []
      insta.remove_methods [:id]
    end

    base.insta_favorite
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at, :approved_at, :bjo_received_at]
    end
    
    base.insta_workflow do |insta|
      insta.add_state_to_english :new, 'New Request'
      insta.add_state_to_english :approved, 'Approved'
      
      insta.add_event_to_english :approve, 'Approve'
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
    base.send :include, AASM
    base.add_aasm
  end
  

  module ModelClassMethods
    def add_aasm
      aasm_column :state
      aasm_initial_state :new

      aasm_state :new
      aasm_state :approved, :enter => [:adjust_approved_at, :try_to_transition_associated_request]

      def self.approved_state
        'approved'
      end
      aasm_event :approve do
        transitions :from => :new, :to => :approved
      end
    end
  end
  
  module ModelInstanceMethods
    def is_approved?
      state.to_s == 'approved'
    end

    def try_to_transition_associated_request
      if request.state == 'pending_secondary_pd_approval'
        if request.all_request_programs_approved? program
          # A little bit odd trickery to convince the request that all request programs are in fact approved; at this point the current request program's state is not yet approved
          cur_state = self.state
          self.state = 'approved'
          request.secondary_pd_approve
          self.state = cur_state
        end
      end
    end

    def adjust_approved_at
      self.approved_at = Time.now
    end
  end
end