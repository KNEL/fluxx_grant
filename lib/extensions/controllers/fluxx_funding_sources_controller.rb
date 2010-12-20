module FluxxFundingSourcesController
  ICON_STYLE = 'style-funding-sources'
  def self.included(base)
    base.insta_index FundingSource do |insta|
      insta.template = 'funding_source_list'
      insta.filter_title = "FundingSources Filter"
      insta.filter_template = 'funding_sources/funding_source_filter'
      insta.order_clause = 'updated_at desc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show FundingSource do |insta|
      insta.template = 'funding_source_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new FundingSource do |insta|
      insta.template = 'funding_source_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit FundingSource do |insta|
      insta.template = 'funding_source_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post FundingSource do |insta|
      insta.template = 'funding_source_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put FundingSource do |insta|
      insta.template = 'funding_source_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete FundingSource do |insta|
      insta.template = 'funding_source_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related FundingSource do |insta|
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