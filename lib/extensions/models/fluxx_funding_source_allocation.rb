module FluxxFundingSourceAllocation
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id]
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :funding_source
    base.belongs_to :program
    base.belongs_to :sub_program
    base.belongs_to :initiative
    base.belongs_to :sub_initiative
    base.belongs_to :authority, :class_name => 'MultiElementValue', :foreign_key => 'authority_id'

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
  end
end