module FluxxGrantedRequestsController
  ICON_STYLE = 'style-granted-requests'
  def self.included(base)
    base.send :include, FluxxCommonRequestsController
    base.insta_index GrantRequest do |insta|
      insta.template = 'granted_requests/grant_request_list'
      insta.filter_title = "Granted Requests Filter"
      insta.filter_template = 'granted_requests/granted_request_filter'
      insta.search_conditions = {:granted => 1, :has_been_rejected => 0}
      insta.suppress_model_anchor_tag = true
      insta.order_clause = 'updated_at desc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show GrantRequest do |insta|
      insta.template = 'grant_requests/grant_request_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          base.grant_request_show_format_html controller_dsl, controller, outcome, default_block
        end
      end
      insta.post do |controller_dsl, controller|
        base.set_enabled_variables controller_dsl, controller
      end
    end
    base.add_grant_request_instal_role
    base.insta_related GrantRequest do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.for_search do |model|
          model.related_users
        end
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.for_search do |model|
          model.related_organizations
        end
        related.display_template = '/organizations/related_organization'
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.for_search do |model|
          model.related_request_transactions
        end
        related.display_template = '/request_transactions/related_request_transactions'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.for_search do |model|
          model.related_request_reports
        end
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