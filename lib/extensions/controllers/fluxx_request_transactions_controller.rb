module FluxxRequestTransactionsController
  def self.included(base)
    base.insta_index RequestTransaction do |insta|
      insta.template = 'request_transaction_list'
      insta.filter_title = "Request Transactions Filter"
      insta.filter_template = 'request_transactions/request_transaction_filter'
    end
    base.insta_show RequestTransaction do |insta|
      insta.template = 'request_transaction_show'
      insta.add_workflow
    end
    base.insta_new RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
    end
    base.insta_edit RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
    end
    base.insta_post RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
    end
    base.insta_put RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.add_workflow
    end
    base.insta_delete RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
    end
    # TODO ESH: do we need insta_role for request transactions??
    base.insta_related RequestTransaction do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = (lambda {|rt| {:request_ids => rt.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'last_name asc, first_name asc'
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.related_class = Organization
        related.search_id = (lambda {|rt| {:request_ids => rt.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'name asc'
        related.display_template = '/organizations/related_organizations'
      end
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.related_class = GrantRequest
        related.search_id = (lambda {|rt| {:sphinx_internal_id => rt.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.related_class = RequestTransaction
        related.search_id = (lambda {|rt| {:grant_ids => rt.request_id} })
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'due_at asc'
        related.display_template = '/request_transactions/related_request_transactions'
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