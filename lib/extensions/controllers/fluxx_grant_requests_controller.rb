module FluxxGrantRequestsController
  def self.included(base)
    base.insta_index GrantRequest do |insta|
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
          end
          default_block.call
        end
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
              controller.flash[:error] = I18n.t(:grant_failed_to_promote_with_exception) + e.to_s + '.'
              controller.redirect_to local_model
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