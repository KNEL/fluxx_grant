module FluxxProgramsController
  def self.included(base)
    base.insta_index Program do |insta|
      insta.template = 'program_list'
      insta.filter_title = "Programs Filter"
      insta.filter_template = 'programs/program_filter'
    end
    base.insta_show Program do |insta|
      insta.template = 'program_show'
    end
    base.insta_new Program do |insta|
      insta.template = 'program_form'
    end
    base.insta_edit Program do |insta|
      insta.template = 'program_form'
    end
    base.insta_post Program do |insta|
      insta.template = 'program_form'
    end
    base.insta_put Program do |insta|
      insta.template = 'program_form'
    end
    base.insta_delete Program do |insta|
      insta.template = 'program_form'
    end
    base.insta_related Program do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :program_id
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