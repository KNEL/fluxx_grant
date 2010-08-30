module FluxxGrantedRequestsController
  def self.included(base)
    base.send :include, FluxxCommonRequestsController
    base.insta_index GrantRequest do |insta|
      insta.template = 'granted_requests/grant_request_list'
      insta.filter_title = "Granted Requests Filter"
      insta.filter_template = 'granted_requests/granted_request_filter'
      insta.search_conditions = {:granted => 1, :has_been_rejected => 0}
      insta.suppress_model_anchor_tag = true
    end
    base.insta_show GrantRequest do |insta|
      insta.add_workflow
      insta.template = 'grant_requests/grant_request_show'
      insta.add_workflow
      insta.post do |controller_dsl, controller|
        base.set_enabled_variables controller_dsl, controller
      end
    end
    base.add_grant_request_instal_role
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
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.related_class = Organization
        related.search_id = [:request_ids, :fiscal_request_ids, :org_request_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'name asc'
        related.display_template = '/organizations/related_organizations'
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.related_class = RequestTransaction
        related.search_id = [:grant_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'due_at asc'
        related.display_template = '/request_transactions/related_request_transactions'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.related_class = RequestReport
        related.search_id = [:grant_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'due_at asc'
        related.display_template = '/request_reports/related_documents'
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