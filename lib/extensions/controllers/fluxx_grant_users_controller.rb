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
    
    # Add in a post method to create a user org if the organization_id param is passed in
    base.insta_post User do |insta|
      insta.post do |controller_dsl, controller, model|
        # Check to see if there was an organization passed in to use to create a user organization
        user = model
        org = Organization.where(:id => user.temp_organization_id).first
        if org 
          user_org = UserOrganization.where(['organization_id = ? AND user_id = ?', org.id, user.id]).first
          user_org || UserOrganization.create(:user => user, :organization => org, :title => user.temp_organization_title)
        end
      end
    end
    
    base.insta_related User do |insta|
      insta.add_related do |related|
        related.display_name = 'Requests'
        related.for_search do |model|
          model.related_requests
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.for_search do |model|
          model.related_grants
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.for_search do |model|
          model.related_organizations
        end
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