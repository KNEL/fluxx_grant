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
    base.insta_related RequestTransaction do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_transaction_id
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