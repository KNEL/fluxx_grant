module FluxxGrantProjectsController
  def self.included(base)
    base.send :include, FluxxProjectsController
    
    base.insta_related Project do |insta|
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.for_search do |model|
          model.related_requests
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.for_search do |model|
          model.related_grants
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/grant_requests/related_request'
      end
    end
    
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