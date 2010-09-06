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
      if fluxx_request
        promotion_events = fluxx_request.current_allowed_events(Request.promotion_events + Request.grant_events)
        allowed_promotion_events = controller.event_allowed?(promotion_events, fluxx_request)
        promotion_event = allowed_promotion_events && allowed_promotion_events.first
      
        # If there is no promote or sendback event available in the workflow, do no let the user edit
        edit_enabled = (!(fluxx_request && fluxx_request.granted) && promotion_event) || 
          (fluxx_request && fluxx_request.state == Request.granted_state.to_s) # && send("#{Request.become_grant_event.to_s}_allowed?"))
        edit_funding_sources_enabled = if !Program.finance_roles.select{|role_name| controller.current_user.has_role? role_name}.empty?
          true
        else
          fluxx_request && !fluxx_request.granted?
        end

        delete_events = fluxx_request.current_allowed_events(Request.promotion_events + Request.grant_events + Request.send_back_events)
        allowed_delete_events = controller.event_allowed?(delete_events, fluxx_request)
        delete_enabled = allowed_delete_events && !allowed_delete_events.empty?
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
    
    
    def add_grant_request_instal_role
      insta_role GrantRequest do |insta|
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
    end
  end

  module ModelInstanceMethods
  end
end