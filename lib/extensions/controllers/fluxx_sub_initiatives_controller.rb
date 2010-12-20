module FluxxSubInitiativesController
  ICON_STYLE = 'style-sub-initiatives'
  def self.included(base)
    base.insta_index SubInitiative do |insta|
      insta.template = 'sub_initiative_list'
      insta.filter_title = "SubInitiatives Filter"
      insta.filter_template = 'sub_initiatives/sub_initiative_filter'
      insta.order_clause = 'name asc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show SubInitiative do |insta|
      insta.template = 'sub_initiative_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new SubInitiative do |insta|
      insta.template = 'sub_initiative_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit SubInitiative do |insta|
      insta.template = 'sub_initiative_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post SubInitiative do |insta|
      insta.template = 'sub_initiative_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put SubInitiative do |insta|
      insta.template = 'sub_initiative_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete SubInitiative do |insta|
      insta.template = 'sub_initiative_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related SubInitiative do |insta|
      insta.add_related do |related|
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