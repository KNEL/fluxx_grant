# File to share functionality among grant/fip/granted request controllers
module FluxxCommonRequestsController
  def self.included(base)
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def add_grant_request_install_role
      insta_role Request do |insta|
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
        insta.add_event_roles 'deputy_director_approve', Program, Program.deputy_director_role_name
        insta.add_event_roles 'deputy_director_send_back', Program, Program.deputy_director_role_name
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
    
    # NOTE: this logic also exists in fluxx_request.rb, we need to keep these two in sync!!!
    def translate_delta_type granted=false
      # Note ESH: we need to not differentiate between FipRequest and GrantRequest so that they can show mixed up within the same card
      'Request' + (granted ? 'Granted' : 'NotYetGranted')
    end
  end

  module ModelInstanceMethods
    def funnel_allowed_states
      Request.all_states - Request.all_rejected_states
    end

    def grant_request_index_format_html controller_dsl, outcome, default_block
      if params[:view_funnel]
        local_models = instance_variable_get '@models'
        funnel_map = WorkflowEvent.workflow_funnel local_models.map(&:id), funnel_allowed_states, Request.sent_back_state_mapping_to_workflow, request.format.csv?
        funnel = funnel_allowed_states.map {|state| funnel_map[:workflow_results][state.to_s]}.compact
        instance_variable_set '@funnel_map', funnel_map
        instance_variable_set '@funnel', funnel
        # TODO ESH: make sure we do skip_favorites
        send :fluxx_show_card, controller_dsl, {:template => 'grant_requests/funnel', :footer_template => 'grant_requests/funnel_footer'}
      else
        default_block.call
      end
    end

    def grant_request_index_format_csv controller_dsl, outcome, default_block
      if params[:view_funnel]
        local_models = instance_variable_get '@models'
        funnel_map = WorkflowEvent.workflow_funnel local_models.map(&:id), funnel_allowed_states, Request.sent_back_state_mapping_to_workflow, request.format.csv?
        filename = 'fluxx_funnel_' + Time.now.strftime("%m%d%y") + '.csv'

        stream_csv( filename ) do |csv|
          csv << ['workflowable_type', 'old_created_at', 'old_state', 'new_created_at', 'new_state', 'days', 'request_id']
          funnel_map[:swe_diffs].each do |swe_diff|
            csv << [swe_diff[:workflowable_type], swe_diff[:old_created_at], swe_diff[:old_state],
              swe_diff[:new_created_at], swe_diff[:new_state], swe_diff[:days], swe_diff[:request_id]]
          end
        end
      else
        default_block.call
      end
    end

    def grant_request_show_format_html controller_dsl, outcome, default_block
      if params[:view_states]
        local_model = instance_variable_get '@model'
        send :fluxx_show_card, controller_dsl, {:template => 'grant_requests/view_states', :footer_template => 'insta/simple_footer'}
      else
        default_block.call
      end
    end

    def grant_request_edit_format_html controller_dsl, outcome, default_block
      if params[:approve_grant_details]
        actual_local_model = instance_variable_get '@model'
        # Need to clone when we run generate grant details or the changes will be persisted; trick rails into thinking this is a new request
        local_model = actual_local_model.clone
        # Trick rails into thinking this is the actual object by setting the ID and setting new_record to false
        local_model.id = actual_local_model.id
        instance_variable_set '@model', local_model
        begin
          local_model.generate_grant_details

          # Trick rails into thinking this is the actual object by setting the ID and setting new_record to false
          local_model.instance_variable_set '@persisted', true
          form_url = send("#{actual_local_model.class.calculate_form_name.to_s}_path", {:id => actual_local_model.id, :event_action => params[:approve_grant_details]})
          send :fluxx_edit_card, controller_dsl, 'grant_requests/approve_grant_details', nil, form_url
        rescue Exception => e
          # p "ESH: have an exception=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
          logger.error "Unable to paint the promote screen; have this error=#{e.inspect}, backtrace=#{e.backtrace.inspect}"
          flash[:error] = I18n.t(:grant_failed_to_promote_with_exception) + e.to_s + '.'
          instance_variable_set "@approve_grant_details_error", true
          redirect_to url_for(actual_local_model)
        end

      else
        default_block.call
      end
    end

    def grant_request_update_format_html controller_dsl, outcome, default_block
      actual_local_model = instance_variable_get '@model'
      event_action = params[:event_action]
      event_action = event_action.to_s.to_sym if event_action
      if Request.all_events_with_category('edit_on_transition').include?(event_action) && outcome == :success
        # redirect to the edit screen IF THE USER
        redirect_to send("edit_#{actual_local_model.class.calculate_form_name.to_s}_path", actual_local_model)
      elsif Request.all_events_with_category('become_grant').include?(event_action) && outcome == :success
        send :fluxx_show_card, controller_dsl, {:template => 'grant_requests/request_became_grant', :footer_template => 'insta/simple_footer'}
      else
        if actual_local_model.granted?
          if outcome == :success
            redirect_to send("granted_request_path", actual_local_model)
          else
            default_block.call
          end
        else
          default_block.call
        end
      end
    end

    def set_enabled_variables controller_dsl
      fluxx_request = instance_variable_get "@model"
      if fluxx_request
        promotion_events = fluxx_request.current_allowed_events(Request.all_workflow_states)
        allowed_promotion_events = event_allowed?(promotion_events, fluxx_request)
        promotion_event = allowed_promotion_events && allowed_promotion_events.first

        # If there is no promote or sendback event available in the workflow, do not let the user edit
        edit_enabled = promotion_event
        delete_events = edit_enabled

        if current_user.has_permission?('admin') || current_user.has_permission?('data_cleanup')
          edit_enabled = true
          delete_enabled = true
        end

        instance_variable_set '@edit_enabled', edit_enabled
        instance_variable_set '@delete_enabled', delete_enabled
      end
    end
  end
end