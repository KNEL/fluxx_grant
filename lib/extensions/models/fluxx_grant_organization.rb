module FluxxGrantOrganization
  SEARCH_ATTRIBUTES = [:parent_org_id, :grant_program_ids, :grant_initiative_ids, :state, :updated_at, :request_ids, :grant_ids, :favorite_user_ids, :related_org_ids]

  def self.included(base)
    base.has_many :grants, :class_name => 'GrantRequest', :foreign_key => :program_organization_id, :conditions => {:granted => 1}
    base.has_many :grant_requests, :class_name => 'Request', :foreign_key => :program_organization_id
    base.has_many :fiscal_requests, :class_name => 'Request', :foreign_key => :fiscal_organization_id
    base.has_many :program_grantees, :class_name => 'Program', :finder_sql => 'select * from programs where id in (select program_id from requests where program_organization_id = #{id} group by program_id)'

    base.insta_search
    base.insta_export
    base.insta_export do |insta|
      insta.filename = 'organization'
      insta.headers = [['Date Created', :date], ['Date Updated', :date], 'name', 'street_address', 'street_address2', 'city', 'state_name', 
                  'country_name', 'postal_code', 'phone', 'other_contact', 'fax', 'email', 'url', 'blog_url', 'twitter_url', 'acronym', 'tax_class']
      insta.sql_query = "select organizations.created_at, organizations.updated_at, organizations.name, street_address, street_address2, city, geo_states.name state_name,  
                  geo_countries.name country_name,
                  postal_code, phone, other_contact, fax, email, url, blog_url, twitter_url, acronym, mev_tax_class.value tax_class_value
                  from organizations
                  left outer join geo_states on geo_states.id = geo_state_id
                  left outer join geo_countries on geo_countries.id = organizations.country_id
                  left outer join multi_element_groups meg_tax_class on meg_tax_class.name = 'tax_classes'
                  left outer join multi_element_values mev_tax_class on multi_element_group_id = meg_tax_class.id and tax_class_id = mev_tax_class.id 
                  WHERE
                  organizations.id IN (?)"
    end
    
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
        indexes "lower(organizations.name)", :as => :name, :sortable => true
        indexes "lower(organizations.acronym)", :as => :acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_initiative_ids
        has grants(:id), :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has request_organizations.request(:id), :type => :multi, :as => :org_request_ids
        has favorites.user(:id), :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids
        has satellite_orgs(:id), :as => :satellite_org_ids
        has "CONCAT(organizations.id, ',', IFNULL(organizations.parent_org_id, '0'))", :as => :related_org_ids, :type => :multi

        set_property :delta => :delayed
      end

      define_index :organization_second do
        indexes "lower(organizations.name)", :as => :name, :sortable => true
        indexes "lower(organizations.acronym)", :as => :acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has grants.program(:id), :as => :grant_program_ids
        has grants.initiative(:id), :as => :grant_initiative_ids
        has 'null', :type => :multi, :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has users(:id), :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids
        has 'null', :type => :multi, :as => :satellite_org_ids
        has 'null', :type => :multi, :as => :related_org_ids

        set_property :delta => :delayed
      end

      define_index :organization_third do
        indexes "lower(organizations.name)", :as => :name, :sortable => true
        indexes "lower(organizations.acronym)", :as => :acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_initiative_ids
        has 'null', :type => :multi, :as => :grant_ids
        has grant_requests(:id), :as => :request_ids
        has fiscal_requests(:id), :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has 'null', :type => :multi, :as => :group_ids
        has 'null', :type => :multi, :as => :satellite_org_ids
        has 'null', :type => :multi, :as => :related_org_ids

        set_property :delta => :delayed
      end

      define_index :organization_fourth do
        indexes "lower(organizations.name)", :as => :name, :sortable => true
        indexes "lower(organizations.acronym)", :as => :acronym, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, state, parent_org_id
        has 'null', :type => :multi, :as => :grant_program_ids
        has 'null', :type => :multi, :as => :grant_initiative_ids
        has 'null', :type => :multi, :as => :grant_ids
        has 'null', :type => :multi, :as => :request_ids
        has 'null', :type => :multi, :as => :fiscal_request_ids
        has 'null', :type => :multi, :as => :org_request_ids
        has 'null', :type => :multi, :as => :favorite_user_ids
        has 'null', :type => :multi, :as => :user_ids
        has group_members.group(:id), :type => :multi, :as => :group_ids
        has 'null', :type => :multi, :as => :satellite_org_ids
        has 'null', :type => :multi, :as => :related_org_ids

        set_property :delta => :delayed
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

    def grant_initiative_ids
      grants.map{|grant| grant.initiative.id if grant.initiative}.flatten.compact
    end
    
    def related_org_ids
      []
    end
    
    def related_requests look_for_granted=false, limit_amount=20
      granted_param = look_for_granted ? 1 : 0
      Request.find_by_sql(["SELECT requests.* 
        FROM requests 
        WHERE deleted_at IS NULL AND (program_organization_id = ? or fiscal_organization_id = ?) AND granted = ?
        UNION
      SELECT requests.* 
        FROM requests, request_organizations 
        WHERE deleted_at IS NULL AND requests.id = request_organizations.request_id AND request_organizations.organization_id = ?
      GROUP BY requests.id 
      ORDER BY grant_agreement_at DESC, request_received_at DESC
      LIMIT ?", self.id, self.id, granted_param, self.id, limit_amount])
    end
    
    def related_grants limit_amount=20
      related_requests true, limit_amount
    end
    
    def related_transactions limit_amount=20
      grants = related_grants limit_amount
      RequestTransaction.where(:deleted_at => nil).where(:request_id => grants.map(&:id)).order('due_at asc').limit(limit_amount)
    end
    
    def related_reports limit_amount=20
      grants = related_grants limit_amount
      RequestReport.where(:deleted_at => nil).where(:request_id => grants.map(&:id)).order('due_at asc').limit(limit_amount)
    end
    
    def related_users limit_amount=20
      users.where(:deleted_at => nil).order('last_name asc, first_name asc').limit(limit_amount)
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