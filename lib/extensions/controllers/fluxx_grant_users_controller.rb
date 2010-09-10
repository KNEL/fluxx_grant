# Supplements FluxxUsersController in fluxx_crm
module FluxxGrantUsersController
  def self.included(base)
    base.insta_index User do |insta|
      insta.filter_title = "Users Filter"
      insta.filter_template = 'users/user_filter'
      insta.pre do |controller_dsl, controller|
        if controller.params[:related_organization_id]
          rel_org_id = controller.params[:related_organization_id]
          controller.pre_models = User.find_by_sql ['SELECT users.* FROM users, user_organizations 
                                 WHERE user_organizations.organization_id IN 
                                 (select distinct(id) from (select id from organizations where id = ? 
                                  union select id from organizations where parent_org_id = ? 
                                  union select id from organizations where parent_org_id = (select parent_org_id from organizations where id = ?) and parent_org_id is not null
                                  union select parent_org_id from organizations where id = ?) all_orgs where id is not null) 
                                 AND user_organizations.user_id = users.id', rel_org_id, rel_org_id, rel_org_id, rel_org_id]
        end
      end
      
    end
    
    base.insta_related User do |insta|
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.related_class = Request
        related.search_id = [:user_ids, :request_user_ids]
        related.extra_condition = {:granted => 0, :deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.related_class = Request
        related.search_id = [:user_ids, :request_user_ids]
        related.extra_condition = {:granted => 1, :deleted_at => 0}
        related.max_results = 20
        related.order = 'grant_agreement_at desc, request_received_at desc'
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.related_class = Organization
        related.search_id = :user_ids
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'name asc'
        related.display_template = '/organizations/related_organization'
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