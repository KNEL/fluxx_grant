module FluxxProgramsController
  ICON_STYLE = 'style-admin-cards'
  def self.included(base)
    base.insta_index Program do |insta|
      insta.template = 'program_list'
      insta.filter_title = "Programs Filter"
      insta.filter_template = 'programs/program_filter'
      insta.order_clause = 'name asc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show Program do |insta|
      insta.template = 'program_show'
      insta.icon_style = ICON_STYLE
    end
    base.insta_new Program do |insta|
      insta.template = 'program_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit Program do |insta|
      insta.template = 'program_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post Program do |insta|
      insta.template = 'program_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put Program do |insta|
      insta.template = 'program_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_delete Program do |insta|
      insta.template = 'program_form'
      insta.icon_style = ICON_STYLE
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