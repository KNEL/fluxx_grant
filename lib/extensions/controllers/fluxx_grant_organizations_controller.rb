# Supplements FluxxOrganizationsController in fluxx_crm
module FluxxGrantOrganizationsController
  def self.included(base)
    base.send :include, FluxxOrganizationsController
    
    base.insta_index Organization do |insta|
      insta.filter_title = "Organizations Filter"
      insta.filter_template = 'organizations/organization_filter'
      insta.search_conditions = (lambda do |params, controller_dsl, controller|
        if params[:related_org_ids]
          {}
        else
          {:parent_org_id => 0}
        end
      end)
    end

    base.insta_show Organization do |insta|
      insta.format do |format|
        format.pdf do |triple|
          controller_dsl, outcome, default_block = triple
          if params[:run_charity_check] == '1'            
            render :text => @model.charity_check_pdf            
          else
            default_block.call
          end
        end        
        format.html do |triple|          
          controller_dsl, outcome, default_block = triple          
          if params[:satellites] == '1'
            send :fluxx_show_card, controller_dsl, {:template => 'organizations/organization_satellites', :footer_template => 'insta/simple_footer', :layout => false}
          elsif params[:run_charity_check] == '1'
            send :fluxx_show_card, controller_dsl, {:template => 'organizations/charity_check_show', :footer_template => 'insta/simple_footer', :layout => false}
          else  
            default_block.call
          end
        end
      end
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        if params[:run_charity_check] == '1'
          model.update_charity_check
        end
        #todo
      end
    end
    
    base.insta_related Organization do |insta|
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.for_search do |model|
          model.related_requests
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.for_search do |model|
          model.related_grants
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/grant_requests/related_request'
        related.add_model_url_block do |model|
          send :granted_request_path, :id => model.id
        end
      end
      insta.add_related do |related|
        related.display_name = 'Outside Grants'
        related.add_lazy_load_url do |model|
          send :outside_grants_path, :id => model.id
        end        
      end      
      insta.add_related do |related|        
        related.display_name = 'People'
        related.for_search do |model|
          model.related_users
        end
        related.add_title_block do |model|
          model.full_name if model
        end
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.for_search do |model|
          model.related_transactions
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/request_transactions/related_request_transactions'
      end
      insta.add_related do |related|
        related.display_name = 'Reports'
        related.for_search do |model|
          model.related_reports
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/request_reports/related_documents'
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