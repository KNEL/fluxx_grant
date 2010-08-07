module FluxxGrantOrganization
  def self.included(base)
    base.has_many :grants, :class_name => 'GrantRequest', :foreign_key => :program_organization_id, :conditions => {:granted => 1}
    base.has_many :grant_requests, :class_name => 'Request', :foreign_key => :program_organization_id
    base.has_many :fiscal_requests, :class_name => 'Request', :foreign_key => :fiscal_organization_id
    base.has_many :program_grantees, :class_name => 'Program', :finder_sql => 'select * from programs where id in (select program_id from requests where program_organization_id = #{id} group by program_id)'

    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_lock

    # AASM doesn't deal with inheritance of active record models quite the way we need here.  Grab Request's state machine as a starting point and modify.
    # AASM::StateMachine[FipRequest] = AASM::StateMachine[Request].clone
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
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