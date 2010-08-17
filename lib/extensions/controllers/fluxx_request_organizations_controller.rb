module FluxxRequestOrganizationsController
  def self.included(base)
    base.insta_index RequestOrganization do |insta|
      insta.template = 'request_organization_list'
      insta.filter_title = "Request Organizations Filter"
      insta.filter_template = 'request_organizations/request_organization_filter'
    end
    base.insta_show RequestOrganization do |insta|
      insta.template = 'request_organization_show'
    end
    base.insta_new RequestOrganization do |insta|
      insta.template = 'request_organization_form'
    end
    base.insta_edit RequestOrganization do |insta|
      insta.template = 'request_organization_form'
    end
    base.insta_post RequestOrganization do |insta|
      insta.template = 'request_organization_form'
    end
    base.insta_put RequestOrganization do |insta|
      insta.template = 'request_organization_form'
    end
    base.insta_delete RequestOrganization do |insta|
      insta.template = 'request_organization_form'
    end
    base.insta_related RequestOrganization do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.related_class = User
        related.search_id = :request_organization_id
        related.extra_condition = {:deleted_at => 0}
        related.max_results = 20
        related.order = 'last_name asc, first_name asc'
        related.display_template = '/users/related_users'
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