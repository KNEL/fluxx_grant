module FluxxRequestReportsController
  def self.included(base)
    base.insta_index RequestReport do |insta|
      insta.template = 'request_report_list'
      insta.filter_title = "Request Reports Filter"
      insta.filter_template = 'request_reports/request_report_filter'
      insta.order_clause = 'due_at desc'
    end
    base.insta_show RequestReport do |insta|
      insta.template = 'request_report_show'
      insta.add_workflow
    end
    base.insta_new RequestReport do |insta|
      insta.template = 'request_report_form'
    end
    base.insta_edit RequestReport do |insta|
      insta.template = 'request_report_form'
    end
    base.insta_post RequestReport do |insta|
      insta.template = 'request_report_form'
    end
    base.insta_put RequestReport do |insta|
      insta.template = 'request_report_form'
      insta.add_workflow
    end
    base.insta_delete RequestReport do |insta|
      insta.template = 'request_report_form'
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
        related.related_class = User
        related.search_id = (lambda {|rd| {:request_ids => rd.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'last_name asc, first_name asc'
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.related_class = Organization
        related.search_id = (lambda {|rd| {:request_ids => rd.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'name asc'
        related.display_template = '/organizations/related_organization'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.related_class = GrantRequest
        related.search_id = (lambda {|rd| {:sphinx_internal_id => rd.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.related_class = RequestReport
        related.search_id = (lambda {|rd| {:grant_ids => rd.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'due_at asc'
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