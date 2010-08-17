module FluxxGrantRequestsController
  def self.included(base)
    base.insta_index GrantRequest do |insta|
      insta.template = 'grant_request_list'
      insta.filter_title = "Grant Requests Filter"
      insta.filter_template = 'grant_requests/grant_request_filter'
    end
    base.insta_show GrantRequest do |insta|
      insta.template = 'grant_request_show'
    end
    base.insta_new GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_edit GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_post GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_put GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_delete GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_related GrantRequest do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :grant_request_id
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