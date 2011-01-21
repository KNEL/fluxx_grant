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
      
      insta.pre do |controller_dsl|
        # We want to use the most proscriptive search in the case that we get more than one limiter passed in
        prog_entity = if !params[:sub_initiative_id].blank?
          SubInitiative.find params[:sub_initiative_id]
        elsif !params[:initiative_id].blank?
          Initiative.find params[:initiative_id]
        elsif !params[:sub_program_id].blank?
          SubProgram.find params[:sub_program_id]
        elsif !params[:program_id].blank?
          Program.find params[:program_id]
        end
        self.pre_models = if prog_entity
          if params[:spending_year].blank?
            prog_entity.funding_source_allocations()
          else
            prog_entity.funding_source_allocations(:spending_year => params[:spending_year])
          end
        else
          []
        end
        
      end
      
      insta.format do |format|
        format.autocomplete do |triple|
          controller_dsl, outcome, default_block = triple
          out_text = @models.map do |model|
              request_amount = params[:funding_amount].to_i if params[:funding_amount] && params[:funding_amount].to_i > 0
              controller_url = url_for(model)
              {:label => model.funding_source_title(request_amount), :value => model.id, :url => controller_url}
            end.to_json
          render :text => out_text, :layout => false
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