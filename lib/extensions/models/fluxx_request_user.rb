module FluxxRequestUser
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :user
    base.acts_as_audited :protect => true
    base.after_commit :update_related_data

    base.validates_presence_of :user_id
    base.validates_presence_of :request_id
    base.validates_uniqueness_of :user_id, :scope => :request_id
    
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
      User.without_delta do
        User.update_all 'delta = 1', ['id in (?)', user_id]
      end
      User.index_delta
    end
  end
end