module FluxxRequestUsersController
  def self.included(base)
    base.insta_index RequestUser do |insta|
      insta.template = 'request_user_list'
      insta.filter_title = "Request Users Filter"
      insta.filter_template = 'request_users/request_user_filter'
    end
    base.insta_show RequestUser do |insta|
      insta.template = 'request_user_show'
    end
    base.insta_new RequestUser do |insta|
      insta.template = 'request_user_form'
    end
    base.insta_edit RequestUser do |insta|
      insta.template = 'request_user_form'
    end
    base.insta_post RequestUser do |insta|
      insta.template = 'request_user_form'
    end
    base.insta_put RequestUser do |insta|
      insta.template = 'request_user_form'
    end
    base.insta_delete RequestUser do |insta|
      insta.template = 'request_user_form'
    end
    base.insta_related RequestUser do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_user_id
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