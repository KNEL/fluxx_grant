module FluxxGrantOrganization
  SEARCH_ATTRIBUTES = [:grant_program_ids, :grant_sub_program_ids, :state, :updated_at, :request_ids, :grant_ids, :favorite_user_ids]

  def self.included(base)
    base.has_many :grants, :class_name => 'GrantRequest', :foreign_key => :program_organization_id, :conditions => {:granted => 1}
    base.has_many :grant_requests, :class_name => 'Request', :foreign_key => :program_organization_id
    base.has_many :fiscal_requests, :class_name => 'Request', :foreign_key => :fiscal_organization_id
    base.has_many :program_grantees, :class_name => 'Program', :finder_sql => 'select * from programs where id in (select program_id from requests where program_organization_id = #{id} group by program_id)'

    base.insta_search
    base.insta_export
    base.insta_multi
    base.insta_lock
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES + [:group_ids]
    end
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    base.add_sphinx if base.respond_to?(:sphinx_indexes) && !(base.connection.adapter_name =~ /SQLite/i)
  end

  module ModelClassMethods
    def add_sphinx
      define_index :organization_first do
        # fields
        indexes name, :sortable => true
        indexes acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_sub_program_ids
        has grants(:id), :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has request_organizations.request(:id), :type => :multi, :as => :org_request_ids
        has favorites.user(:id), :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids

        set_property :delta => true
      end

      define_index :organization_second do
        indexes name, :sortable => true
        indexes acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has grants.program(:id), :as => :grant_program_ids
        has grants.sub_program(:id), :as => :grant_sub_program_ids
        has 'null', :type => :multi, :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has users(:id), :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids

        set_property :delta => true
      end

      define_index :organization_third do
        indexes name, :sortable => true
        indexes acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_sub_program_ids
        has 'null', :type => :multi, :as => :grant_ids
        has grant_requests(:id), :as => :request_ids
        has fiscal_requests(:id), :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids

        set_property :delta => true
      end

      define_index :organization_fourth do
        indexes name, :sortable => true
        indexes acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_sub_program_ids
        has 'null', :type => :multi, :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has group_members.group(:id), :type => :multi, :as => :group_ids

        set_property :delta => true
      end
    end
  end

  module ModelInstanceMethods
    def request_ids
      grant_requests.map{|request| request.id}.flatten.compact
    end

    def grant_ids
      grants.map{|grant| grant.id}.flatten.compact
    end

    def auto_complete_name
      if is_headquarters?
        "#{name} - headquarters"
      else
        "#{name} - #{[street_address, city].compact.join ', '}"
      end
    end

    # Check if this is a satellite location and if so grab the tax class from the headquarters 
    def hq_tax_class
      if is_satellite? && parent_org
        parent_org.tax_class
      else
        tax_class
      end
    end

    def grant_program_ids
      grants.map{|grant| grant.program.id if grant.program}.flatten.compact
    end

    def grant_sub_program_ids
      grants.map{|grant| grant.sub_program.id if grant.sub_program}.flatten.compact
    end

    def is_trusted?
      !grants.empty?
    end

    def is_er?
      tax_class_value = self.hq_tax_class ? self.hq_tax_class.value : ''
      case tax_class_value
      when '509a1': false
      when '509a2': false
      when '509a3': false
      when 'Private Foundation': true
      when '501c4': true
      when '501c6': true
      when 'non-US': true
      when 'Non-Exempt': true
      else
        raise "Invalid tax_class: '#{tax_class_value}'" 
      end
    end
  end
end