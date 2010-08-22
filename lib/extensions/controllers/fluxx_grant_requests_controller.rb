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
    end
    base.insta_new GrantRequest do |insta|
      insta.template = 'grant_request_form'
    end
    base.insta_edit GrantRequest do |insta|
      insta.template = 'grant_request_form'
      # ESH: hmmm, look into a way to set the context to be the same as the controller's
      insta.format do |format|
        format.html do |controller_dsl, controller, outcome, default_block|
          p "ESH: in Grant Request edit block for HTML.  Have params=#{controller.params.inspect}"
          if controller.params[:approve_grant_details]
            local_model = controller.instance_variable_get '@model'
            local_model = local_model.clone
            controller.instance_variable_set '@model', local_model
            begin
              p "ESH: 111 about to generate grant details"
              local_model.generate_grant_details
              p "ESH: 222 after generating grant details"
              controller.send :fluxx_edit_card, controller_dsl, 'grant_requests/approve_grant_details'
              p "ESH: 333 after requesting grant_requests/approve_grant_details"
            rescue Exception => e
              p "ESH: 444 have an exception #{e.inspect}"
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