module FluxxProjectRequest
  SEARCH_ATTRIBUTES = [:created_at, :updated_at]

  def self.included(base)
    base.belongs_to :project
    base.belongs_to :request
    base.acts_as_audited
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
  end
end