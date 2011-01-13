module FluxxFundingSourceAllocation
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :program_id, :sub_program_id, :initiative_id, :sub_initiative_id, :authority_id]
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :funding_source
    base.belongs_to :program
    base.belongs_to :sub_program
    base.belongs_to :initiative
    base.belongs_to :sub_initiative
    base.belongs_to :authority, :class_name => 'MultiElementValue', :foreign_key => 'authority_id'
    base.has_many :request_funding_sources

    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {}
    end

    base.insta_multi
    base.insta_export do |insta|
      insta.filename = 'funding_source_allocation'
      insta.headers = [['Date Created', :date], ['Date Updated', :date]]
      insta.sql_query = "select created_at, updated_at
                from funding_source_allocations
                where id IN (?)"
    end
    base.insta_lock

    base.insta_utc do |insta|
      insta.time_attributes = [] 
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
  end
  

  module ModelClassMethods
  end
  
  module ModelInstanceMethods
    def amount_granted
      request_funding_sources.select{|rfs| rfs.request.granted}.inject(0){|acc, rfs| acc + rfs.funding_amount}
    end
    
    def amount_remaining
      (amount || 0) - (amount_granted || 0)
    end

    def amount_granted_in_queue
      request_funding_sources.reject{|rfs| rfs.request.granted}.inject(0){|acc, rfs| acc + rfs.funding_amount}
    end
    
    def composite_name
      program_name = program.name if program
      sub_program_name = sub_program.name if sub_program
      initiative_name = initiative.name if initiative
      sub_initiative_name = sub_initiative.name if sub_initiative
      "#{funding_source ? funding_source.name : ''} - #{program_name} - #{sub_program_name} - #{initiative_name} - #{sub_initiative_name}"
    end
    def title
      "#{composite_name}; Total: #{amount}, Remaining: #{(amount || 0) - (amount_granted || 0)}"
    end
    
    def autocomplete_to_s
      title
    end
  end
end