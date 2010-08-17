module FluxxRequestLettersController
  def self.included(base)
    base.insta_index RequestLetter do |insta|
      insta.template = 'request_letter_list'
      insta.filter_title = "Request Letters Filter"
      insta.filter_template = 'request_letters/request_letter_filter'
    end
    base.insta_show RequestLetter do |insta|
      insta.template = 'request_letter_show'
    end
    base.insta_new RequestLetter do |insta|
      insta.template = 'request_letter_form'
    end
    base.insta_edit RequestLetter do |insta|
      insta.template = 'request_letter_form'
    end
    base.insta_post RequestLetter do |insta|
      insta.template = 'request_letter_form'
    end
    base.insta_put RequestLetter do |insta|
      insta.template = 'request_letter_form'
    end
    base.insta_delete RequestLetter do |insta|
      insta.template = 'request_letter_form'
    end
    base.insta_related RequestLetter do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_letter_id
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