module FluxxFipRequest
  def self.included(base)
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})

    base.validates_presence_of     :fip_title
    base.validates_presence_of     :fip_type
    base.validates_presence_of     :fip_projected_end_at
    base.validates_presence_of     :program
    base.validates_presence_of     :project_summary
    base.validates_presence_of     :amount_requested
    base.validates_presence_of     :amount_recommended, :if => :state_after_pre_recommended_chain
    base.validates_associated      :program
    base.has_many :workflow_events, :foreign_key => :workflowable_id, :conditions => {:workflowable_type => base.name}
    base.has_many :favorites, :foreign_key => :favorable_id, :conditions => {:favorable_type => base.name}
    base.has_many :notes, :foreign_key => :notable_id, :conditions => {:notable_type => base.name}
    base.has_many :group_members, :foreign_key => :groupable_id, :conditions => {:groupable_type => base.name}
    base.has_many :model_documents, :foreign_key => :documentable_id, :conditions => {:documentable_type => base.name}
    base.has_many :wiki_documents, :foreign_key => :model_id, :conditions => {:model_type => base.name}

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def model_name
      u = ActiveModel::Name.new FipRequest
      u.instance_variable_set '@human', "#{I18n.t(:fip_name)} Request"
      u
    end
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