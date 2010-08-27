module FluxxCommonRequestsController
  def self.included(base)
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def set_enabled_variables controller_dsl, controller
      fluxx_request = controller.instance_variable_get "@model"
      promotion_events = fluxx_request.current_allowed_events(Request.promotion_events + Request.grant_events)
      promotion_event = controller.event_allowed?(promotion_events, fluxx_request).first
      
      # If there is no promote or sendback event available in the workflow, do no let the user edit
      edit_enabled = (!(fluxx_request && fluxx_request.granted) && promotion_event) || 
        (fluxx_request && fluxx_request.state == Request.granted_state.to_s) # && send("#{Request.become_grant_event.to_s}_allowed?"))
      edit_funding_sources_enabled = if !Program.finance_roles.select{|role_name| controller.current_user.has_role? role_name}.empty?
        true
      else
        fluxx_request && !fluxx_request.granted?
      end

      delete_events = fluxx_request.current_allowed_events(Request.promotion_events + Request.grant_events + Request.send_back_events)
      delete_enabled = !controller.event_allowed?(delete_events, fluxx_request).empty?
      if controller.current_user.has_role?('admin', User) || controller.current_user.has_role?('data_cleanup', User)
        edit_enabled = true
        edit_funding_sources_enabled = true
        delete_enabled = true
      end
      
      controller.instance_variable_set '@edit_enabled', edit_enabled
      controller.instance_variable_set '@edit_funding_sources_enabled', edit_funding_sources_enabled
      controller.instance_variable_set '@delete_enabled', delete_enabled
    end
  end

  module ModelInstanceMethods
  end
end