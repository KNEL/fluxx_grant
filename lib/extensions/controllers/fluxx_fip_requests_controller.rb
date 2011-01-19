module FluxxFipRequestsController
  ICON_STYLE = 'style-fip-requests'
  def self.included(base)
    base.send :include, FluxxCommonRequestsController
    base.insta_index Request do |insta|
      insta.search_conditions = {:granted => 0, :has_been_rejected => 0}
      insta.template = 'grant_requests/grant_request_list'
      insta.filter_title = "#{I18n.t(:fip_name)} Requests Filter"
      insta.filter_template = 'fip_request_filter'
      insta.order_clause = 'updated_at desc'
      insta.icon_style = ICON_STYLE
      insta.delta_type = Request.translate_delta_type false # Vary the request type based on whether a request has been granted yet or not
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          grant_request_index_format_html controller_dsl, outcome, default_block
        end
      end
    end
    base.insta_show FipRequest do |insta|
      insta.template = 'grant_requests/grant_request_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          grant_request_show_format_html controller_dsl, outcome, default_block
        end
      end
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        set_enabled_variables controller_dsl
      end
    end
    base.add_grant_request_install_role
    base.insta_new FipRequest do |insta|
      insta.template = 'fip_requests/fip_request_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit FipRequest do |insta|
      insta.template = 'fip_requests/fip_request_form'
      insta.icon_style = ICON_STYLE
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          grant_request_edit_format_html controller_dsl, outcome, default_block
        end
      end
    end
    base.insta_post FipRequest do |insta|
      insta.template = 'fip_requests/fip_request_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put FipRequest do |insta|
      insta.template = 'fip_requests/fip_request_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
      insta.format do |format|
        format.html do |triple|
          controller_dsl, outcome, default_block = triple
          grant_request_update_format_html controller_dsl, outcome, default_block
        end
      end
    end
    base.insta_delete FipRequest do |insta|
      insta.template = 'fip_requests/fip_request_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related FipRequest do |insta|
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