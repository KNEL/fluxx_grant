module FluxxFipRequest
  def self.included(base)
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta], :protect => true})

    base.validates_presence_of     :fip_title
    base.validates_presence_of     :fip_projected_end_at
    base.validates_presence_of     :program
    base.validates_presence_of     :project_summary
    base.validates_presence_of     :amount_requested
    base.validates_presence_of     :amount_recommended, :if => :state_after_pre_recommended_chain
    base.validates_associated      :program

    # AASM doesn't deal with inheritance of active record models quite the way we need here.  Grab Request's state machine as a starting point and modify.
    # AASM::StateMachine[FipRequest] = AASM::StateMachine[Request].clone
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def request_prefix
      'FR'
    end

    def grant_prefix
      'FG'
    end

    def generate_grant_details
      generate_grant_dates
    end
  end
end