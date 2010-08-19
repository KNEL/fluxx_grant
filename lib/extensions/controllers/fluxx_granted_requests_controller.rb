module FluxxGrantedRequestsController
  def self.included(base)
    base.insta_index GrantRequest do |insta|
      insta.template = 'granted_request_list'
      insta.filter_title = "Granted Requests Filter"
      insta.filter_template = 'granted_requests/granted_requet_filter'
    end
    base.insta_show GrantRequest do |insta|
      insta.template = 'granted_request_show'
      insta.add_workflow
    end
    base.insta_new GrantRequest do |insta|
      insta.template = 'granted_request_form'
    end
    base.insta_edit GrantRequest do |insta|
      insta.template = 'granted_request_form'
    end
    base.insta_post GrantRequest do |insta|
      insta.template = 'granted_request_form'
    end
    base.insta_put GrantRequest do |insta|
      insta.template = 'granted_request_form'
      insta.add_workflow
    end
    base.insta_delete GrantRequest do |insta|
      insta.template = 'granted_request_form'
    end
    base.insta_related GrantRequest do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :granted_request_id
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'last_name asc, first_name asc'
        related.display_template = '/users/related_users'
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