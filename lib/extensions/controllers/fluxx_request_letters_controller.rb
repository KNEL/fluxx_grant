module FluxxRequestLettersController
  def self.included(base)
    base.insta_index RequestLetter do |insta|
      insta.template = 'request_letter_list'
      insta.filter_title = "Request Letters Filter"
      insta.filter_template = 'request_letters/request_letter_filter'
    end
    base.insta_show RequestLetter do |insta|
      insta.pre do |conf, controller|
        controller.instance_variable_set '@skip_wrapper', true
      end
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