module FluxxRequestReportsController
  def self.included(base)
    base.insta_index RequestReport do |insta|
      insta.template = 'request_report_list'
      insta.filter_title = "Request Reports Filter"
      insta.filter_template = 'request_reports/request_report_filter'
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
    base.insta_related RequestReport do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_report_id
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