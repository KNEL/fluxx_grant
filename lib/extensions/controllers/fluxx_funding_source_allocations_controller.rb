module FluxxFundingSourceAllocationsController
  ICON_STYLE = 'style-funding-source-allocations'
  def self.included(base)
    base.insta_index FundingSourceAllocation do |insta|
      insta.template = 'funding_source_allocation_list'
      insta.order_clause = 'updated_at desc'
      insta.results_per_page = 500
      insta.include_relation = :funding_source
      insta.order_clause = 'funding_sources.name asc'
      insta.icon_style = ICON_STYLE
      insta.suppress_model_iteration = true
      insta.format do |format|
        format.autocomplete do |triple|
          controller_dsl, outcome, default_block = triple
          out_text = @models.map do |model|
              amount_remaining = model.amount_remaining
              request_amount = params[:amount].to_i if params[:amount] && params[:amount].to_i > 0
              funds_available = if request_amount
                if amount_remaining > request_amount
                  amount_remaining.to_currency
                else
                  "Less than #{request_amount.to_currency} available"
                end
              else
                amount_remaining.to_currency
              end
              controller_url = url_for(model)
              {:label => "#{model.funding_source ? model.funding_source.name : ''}: #{funds_available}", :value => model.id, :url => controller_url}
            end.to_json
          render :text => out_text
        end
      end
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