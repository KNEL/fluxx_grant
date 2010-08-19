module FluxxGrantUser
  SEARCH_ATTRIBUTES = [:state, :updated_at, :first_name, :last_name]
  def self.included(base)
    base.has_many :request_users
    base.has_many :users, :through => :request_users
    base.has_many :program_lead_requests, :class_name => 'Request', :foreign_key => :program_lead_id
    base.has_many :grantee_org_owner_requests, :class_name => 'Request', :foreign_key => :grantee_org_owner_id
    base.has_many :grantee_signatory_requests, :class_name => 'Request', :foreign_key => :grantee_signatory_id
    base.has_many :fiscal_org_owner_requests, :class_name => 'Request', :foreign_key => :fiscal_org_owner_id
    base.has_many :fiscal_signatory_requests, :class_name => 'Request', :foreign_key => :fiscal_signatory_id
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_export do |insta|
      insta.filename = 'user'
      insta.headers = [['Date Created', :date], ['Date Updated', :date], 'salutation', 'first_name', 'last_name', 'email', 'personal_email', 'prefix', 'middle_initial', 'personal_phone', 
                      'personal_mobile', 'personal_fax',
                      'personal_street_address', 'personal_street_address2', 'personal_city', 'state_name', 'country_name', 'personal_postal_code', 'work_street_address', 'work_street_address2', 
                      'work_city', 'work_state', 'work_country', 'work_postal_code', 'work_phone', 'work_fax', 'other_contact',
                      'assistant_name', 'assistant_email', 'blog_url', 'twitter_url', ['Birthday', :date], 'primary_title', 'primary_organization', 'time_zone']
      insta.sql_query = "select users.created_at, users.updated_at, salutation, first_name, last_name, users.email, personal_email, prefix, middle_initial, personal_phone, personal_mobile, personal_fax,
                      personal_street_address, personal_street_address2, personal_city, country_states.name state_name,  countries.name country_name, personal_postal_code, 
                      organizations.street_address work_street_address, organizations.street_address2 work_street_address2, organizations.city work_city,
                      work_country_states.name work_state_name, work_countries.name work_country_name, organizations.postal_code work_postal_code,
                      work_phone, work_fax, users.other_contact, 
                      assistant_name, assistant_email, users.blog_url, users.twitter_url, birth_at, 
                      user_organizations.title organization_title, organizations.name primary_organization, time_zone
                      from users 
                      left outer join country_states on country_states.id = personal_country_state_id
                      left outer join countries on countries.id = personal_country_id
                      left outer join user_organizations on user_organizations.id = primary_user_organization_id
                      left outer join organizations on organizations.id = user_organizations.organization_id
                      left outer join country_states as work_country_states on work_country_states.id = organizations.country_state_id
                      left outer join countries as work_countries on work_countries.id = organizations.country_id
                      where users.id IN (?)"
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
    base.add_sphinx if base.respond_to?(:sphinx_indexes) && !(base.connection.adapter_name =~ /SQLite/i)
  end

  module ModelClassMethods
    def add_sphinx
      define_index :user_first do
        # fields
        indexes first_name, last_name, email, :sortable => true
        indexes 'null', :type => :string, :as => :full_name, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at

        has roles_users.any_request_type_role.any_request(:id), :as => :request_ids
        has roles_users.grant_role.grant.program(:id), :as => :grant_program_ids
        has roles_users.grant_role.grant.sub_program(:id), :as => :grant_sub_program_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :organization_id
        has 'null', :type => :multi, :as => :last_name_ord
        has 'null', :type => :multi, :as => :first_name_ord
        has request_users.request(:id), :type => :multi, :as => :user_request_ids
        has 'null', :type => :multi, :as => :group_ids
        set_property :delta => true
      end

      define_index :user_second do
        # fields
        indexes first_name, last_name, email, :sortable => true
        indexes "TRIM(CONCAT(CONCAT(IFNULL(users.first_name, ' '), ' '), IFNULL(users.last_name, ' ')))", :as => :full_name, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at

        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_sub_program_ids
        has favorites.user(:id), :as => :favorite_user_ids
        has user_organizations.organization(:id), :as => :organization_id
        has '((ORD(LOWER(SUBSTRING(users.last_name,1,1))) * 16777216) + (ORD(LOWER(SUBSTRING(users.last_name,2,1))) * 65536) +
        (ORD(LOWER(SUBSTRING(users.last_name,3,1))) * 256) + (ORD(LOWER(SUBSTRING(users.last_name,4,1)))))', :type => :multi, :as => :last_name_ord
        has '((ORD(LOWER(SUBSTRING(users.first_name,1,1))) * 16777216) + (ORD(LOWER(SUBSTRING(users.first_name,2,1))) * 65536) +
        (ORD(LOWER(SUBSTRING(users.first_name,3,1))) * 256) + (ORD(LOWER(SUBSTRING(users.first_name,4,1)))))', :type => :multi, :as => :first_name_ord
        has 'null', :type => :multi, :as => :user_request_ids
        has group_members.group(:id), :type => :multi, :as => :group_ids
        set_property :delta => true
      end
    end
  end

  module ModelInstanceMethods
  end
end