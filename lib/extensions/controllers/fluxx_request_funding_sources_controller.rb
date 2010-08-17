module FluxxRequestFundingSourcesController
  def self.included(base)
    base.insta_index RequestFundingSource do |insta|
      insta.template = 'request_funding_source_list'
      insta.filter_title = "Request Funding Sources Filter"
      insta.filter_template = 'request_funding_sources/request_funding_source_filter'
    end
    base.insta_show RequestFundingSource do |insta|
      insta.template = 'request_funding_source_show'
    end
    base.insta_new RequestFundingSource do |insta|
      insta.template = 'request_funding_source_form'
    end
    base.insta_edit RequestFundingSource do |insta|
      insta.template = 'request_funding_source_form'
    end
    base.insta_post RequestFundingSource do |insta|
      insta.template = 'request_funding_source_form'
    end
    base.insta_put RequestFundingSource do |insta|
      insta.template = 'request_funding_source_form'
    end
    base.insta_delete RequestFundingSource do |insta|
      insta.template = 'request_funding_source_form'
    end
    base.insta_related RequestFundingSource do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_funding_source_id
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