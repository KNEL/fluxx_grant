module FluxxGrantRequestsController
  def self.included(base)
    base.send :include, FluxxCommonRequestsController
    base.insta_index GrantRequest do |insta|
      insta.search_conditions = {:granted => 0, :has_been_rejected => 0}
      insta.template = 'grant_request_list'
      insta.filter_title = "Grant Requests Filter"
      insta.filter_template = 'grant_requests/grant_request_filter'
    end
    base.insta_show GrantRequest do |insta|
      insta.template = 'grant_request_show'
      insta.add_workflow
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          if controller.params[:view_states]
            local_model = controller.instance_variable_get '@model'
            fluxx_show_card local_model, {:template => 'grant_requests/view_states', :footer_template => 'insta/simple_footer'}
          elsif controller.params[:show_funding_sources]
          end
          default_block.call
        end
      end
      insta.post do |controller_dsl, controller|
        base.set_enabled_variables controller_dsl, controller
      end
    end
    base.insta_role GrantRequest do |insta|
      # Define who is allowd to perform which events
      insta.add_event_roles 'reject', Program, Program.request_roles
      insta.add_event_roles 'un_reject', Program, Program.request_roles
      insta.add_event_roles 'recommend_funding', Program, Program.request_roles
      insta.add_event_roles 'complete_ierf', Program, Program.request_roles
      insta.add_event_roles 'grant_team_approve', Program, Program.grant_roles
      insta.add_event_roles 'grant_team_send_back', Program, Program.grant_roles
      insta.add_event_roles 'po_approve', Program, Program.program_officer_role_name
      insta.add_event_roles 'po_send_back', Program, Program.program_officer_role_name
      insta.add_event_roles 'pd_approve', Program, Program.program_director_role_name
      insta.add_event_roles 'secondary_pd_approve', Program, Program.program_director_role_name
      insta.add_event_roles 'pd_send_back', Program, Program.program_director_role_name
      insta.add_event_roles 'cr_approve', Program, Program.cr_role_name
      insta.add_event_roles 'cr_send_back', Program, Program.cr_role_name
      insta.add_event_roles 'svp_approve', Program, Program.svp_role_name
      insta.add_event_roles 'svp_send_back', Program, Program.svp_role_name
      insta.add_event_roles 'president_approve', Program, Program.president_role_name
      insta.add_event_roles 'president_send_back', Program, Program.president_role_name
      insta.add_event_roles 'become_grant', Program, Program.grant_roles
      insta.add_event_roles 'close_grant', Program, Program.grant_roles
      insta.add_event_roles 'cancel_grant', Program, Program.grant_roles
      
      insta.extract_related_object do |model|
        model.program
      end
    end
    base.insta_new GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_edit GrantRequest do |insta|
      insta.template = 'grant_request_form'
      # ESH: hmmm this is a bit ugly; look into a way to set the context to be the same as the controller's
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          if controller.params[:approve_grant_details]
            local_model = controller.instance_variable_get '@model'
            local_model = local_model.clone
            controller.instance_variable_set '@model', local_model
            begin
              local_model.generate_grant_details
              controller.send :fluxx_edit_card, controller_dsl, 'grant_requests/approve_grant_details'
            rescue Exception => e
              #p "ESH: have an exception=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
              controller.logger.error "Unable to paint the promote screen; have this error=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
              controller.flash[:error] = I18n.t(:grant_failed_to_promote_with_exception) + e.to_s + '.'
              default_block.call
            end
            
          else
            default_block.call
          end
        end
      end
      
    end
    base.insta_post GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_put GrantRequest do |insta|
      insta.template = 'grant_request_form'
      insta.add_workflow
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
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.related_class = Organization
        related.search_id = [:request_ids, :fiscal_request_ids, :org_request_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'name asc'
        related.display_template = '/organizations/related_organizations'
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