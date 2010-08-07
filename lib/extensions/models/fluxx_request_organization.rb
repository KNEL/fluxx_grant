module FluxxRequestOrganization
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :organization
    base.after_commit :update_related_data
    base.acts_as_audited :protect => true

    base.validates_presence_of :organization_id
    base.validates_presence_of :request_id
    base.validates_uniqueness_of :organization_id, :scope => :request_id
    
    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_lock
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def update_related_data
      Request.without_delta do
        Request.update_all 'delta = 1', ['id in (?)', request_id]
      end
      Request.index_delta
      Organization.without_delta do
        Organization.update_all 'delta = 1', ['id in (?)', organization_id]
      end
      Organization.index_delta
    end
  end
end