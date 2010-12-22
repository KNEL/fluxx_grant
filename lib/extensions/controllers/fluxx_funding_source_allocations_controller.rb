module FluxxFundingSourceAllocationsController
  ICON_STYLE = 'style-funding-source-allocations'
  def self.included(base)
    base.insta_index FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_list'
      insta.filter_title = "FundingSourceAllocations Filter"
      insta.filter_template = 'funding_source_allocations/funding_source_allocation_filter'
      insta.order_clause = 'updated_at desc'
      insta.results_per_page = 500
      insta.include_relation = :funding_source
      insta.order_clause = 'funding_sources.name asc'
      insta.icon_style = ICON_STYLE
      insta.suppress_model_iteration = true
    end
    base.insta_show FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_new FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_edit FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_put FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
    end
    base.insta_delete FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_related FundingSourceAllocation do |insta|
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