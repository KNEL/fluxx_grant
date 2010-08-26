# Supplements FluxxOrganizationsController in fluxx_crm
module FluxxGrantOrganizationsController
  def self.included(base)
    base.insta_index Organization do |insta|
      insta.filter_title = "Organizations Filter"
      insta.filter_template = 'organizations/organization_filter'
    end
    
    base.insta_related Organization do |insta|
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.related_class = Request
        related.search_id = [:related_request_organization_ids, :request_org_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.related_class = Request
        related.search_id = [:related_grant_organization_ids, :grant_org_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :organization_id
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'last_name asc, first_name asc'
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.related_class = RequestTransaction
        related.search_id = [:related_organization_ids]
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'due_at asc'
        related.display_template = '/request_transactions/related_request_transactions'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.related_class = RequestReport
        related.search_id = [:related_organization_ids]
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