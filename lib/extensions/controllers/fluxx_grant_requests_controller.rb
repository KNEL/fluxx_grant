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
    base.add_grant_request_instal_role
    base.insta_new GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_edit GrantRequest do |insta|
      insta.template = 'grant_request_form'
      # ESH: hmmm this is a bit ugly; look into a way to set the context to be the same as the controller's
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          if controller.params[:approve_grant_details]
            actual_local_model = controller.instance_variable_get '@model'
            # Need to clone when we run generate grant details or the changes will be persisted; trick rails into thinking this is a new request
            local_model = actual_local_model.clone
            # Trick rails into thinking this is the actual object by setting the ID and setting new_record to false
            local_model.id = actual_local_model.id
            controller.instance_variable_set '@model', local_model
            begin
              local_model.generate_grant_details

              # Trick rails into thinking this is the actual object by setting the ID and setting new_record to false
              local_model.instance_variable_set '@new_record', false
              form_url = controller.send("#{actual_local_model.class.name.underscore.downcase}_path", {:id => actual_local_model.id, :event_action => Request.become_grant_event})
              controller.send :fluxx_edit_card, controller_dsl, 'grant_requests/approve_grant_details', nil, form_url
            rescue Exception => e
              # p "ESH: have an exception=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
              controller.logger.error "Unable to paint the promote screen; have this error=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
              controller.flash[:error] = I18n.t(:grant_failed_to_promote_with_exception) + e.to_s + '.'
              controller.instance_variable_set "@approve_grant_details_error", true
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
        related.search_id = :request_ids
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