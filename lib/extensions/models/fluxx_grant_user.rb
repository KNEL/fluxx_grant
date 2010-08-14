module FluxxGrantUser
  def self.included(base)
    base.has_many :request_users
    base.has_many :users, :through => :request_users
    base.has_many :program_lead_requests, :class_name => 'Request', :foreign_key => :program_lead_id
    base.has_many :grantee_org_owner_requests, :class_name => 'Request', :foreign_key => :grantee_org_owner_id
    base.has_many :grantee_signatory_requests, :class_name => 'Request', :foreign_key => :grantee_signatory_id
    base.has_many :fiscal_org_owner_requests, :class_name => 'Request', :foreign_key => :fiscal_org_owner_id
    base.has_many :fiscal_signatory_requests, :class_name => 'Request', :foreign_key => :fiscal_signatory_id
    
    
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