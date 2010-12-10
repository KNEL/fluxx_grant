module FluxxRequestReportsController
  ICON_STYLE = 'style-reports'
  def self.included(base)
    base.insta_index RequestReport do |insta|
      insta.template = 'request_report_list'
      insta.filter_title = "Grantee Reports Filter"
      insta.filter_template = 'request_reports/request_report_filter'
      insta.order_clause = 'due_at desc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show RequestReport do |insta|
      insta.template = 'request_report_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_role RequestReport do |insta|
      # Define who is allowd to perform which events
      insta.add_event_roles RequestReport.submit_report_event, Program, Program.request_roles
      insta.add_event_roles RequestReport.lead_approve_event, Program, [Program.program_officer_role_name, Program.program_director_role_name]
      insta.add_event_roles RequestReport.lead_send_back_event, Program, [Program.program_director_role_name, Program.program_officer_role_name]
      insta.add_event_roles RequestReport.grant_team_approve_event, Program, Program.grant_roles
      insta.add_event_roles RequestReport.grant_team_send_back_event, Program, Program.grant_roles
      insta.add_event_roles RequestReport.finance_approve_event, Program, Program.finance_roles
      insta.add_event_roles RequestReport.finance_send_back_event, Program, Program.finance_roles

      insta.extract_related_object do |model|
        model.request.program if model.request
      end
    end
    
    base.insta_related RequestReport do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.for_search do |model|
          model.related_users
        end
        related.add_title_block do |model|
          model.full_name if model
        end
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.for_search do |model|
          model.related_organizations
        end
        related.add_title_block do |model|
          model.name if model
        end
        related.display_template = '/organizations/related_organization'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.for_search do |model|
          model.related_grants
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.add_model_url_block do |controller, model|
          controller.send :granted_request_path, :id => model.id
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.for_search do |model|
          model.related_reports
        end
        related.add_title_block do |model|
          model.title if model
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