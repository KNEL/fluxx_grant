module FluxxInitiativesController
  def self.included(base)
    base.insta_index Initiative do |insta|
      insta.template = 'initiative_list'
      insta.filter_title = "Initiatives Filter"
      insta.filter_template = 'initiatives/initiative_filter'
      insta.order_clause = 'name asc'
    end
    base.insta_show Initiative do |insta|
      insta.template = 'initiative_show'
    end
    base.insta_new Initiative do |insta|
      insta.template = 'initiative_form'
    end
    base.insta_edit Initiative do |insta|
      insta.template = 'initiative_form'
    end
    base.insta_post Initiative do |insta|
      insta.template = 'initiative_form'
    end
    base.insta_put Initiative do |insta|
      insta.template = 'initiative_form'
    end
    base.insta_delete Initiative do |insta|
      insta.template = 'initiative_form'
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