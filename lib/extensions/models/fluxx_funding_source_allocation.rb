module FluxxFundingSourceAllocation
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :program_id, :sub_program_id, :initiative_id, :sub_initiative_id, :authority_id, :spending_year]
  
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
    base.validates_presence_of :funding_source
    base.validates_presence_of :amount
    base.validates_presence_of :spending_year
    base.validates_presence_of :authority

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
    def build_temp_table
      temp_table = self.name.underscore + "_tmp"
      FundingSourceAllocation.connection.execute "DROP TABLE IF EXISTS #{temp_table}"
      FundingSourceAllocation.connection.execute "create temporary table #{temp_table} 
          select funding_source_allocations.id, 
            if(program_id is not null, program_id, 
              if(sub_program_id is not null, (select program_id from sub_programs where id = sub_program_id),
                if(initiative_id is not null, (select program_id from sub_programs where id = (select sub_program_id from initiatives where initiatives.id = initiative_id)), 
                  if(sub_initiative_id is not null, (select program_id from sub_programs where id = (select sub_program_id from initiatives where initiatives.id = (select initiative_id from sub_initiatives where sub_initiatives.id = sub_initiative_id))), null)))) program_id,
            if(sub_program_id is not null, sub_program_id,
        			if(initiative_id is not null, (select sub_program_id from initiatives where initiatives.id = initiative_id),
                if(sub_initiative_id is not null, (select sub_program_id from initiatives where initiatives.id = (select initiative_id from sub_initiatives where sub_initiatives.id = sub_initiative_id)), null))) sub_program_id,
         		if(initiative_id is not null, initiative_id, 
              if(sub_initiative_id is not null, (select initiative_id from sub_initiatives where sub_initiatives.id = sub_initiative_id), null)) initiative_id,
            sub_initiative_id,
           deleted_at, spending_year, retired, amount, authority_id, funding_source_id
           from funding_source_allocations"
      retval = yield temp_table
      FundingSourceAllocation.connection.execute("DROP TABLE IF EXISTS #{temp_table}")
      retval
    end
  end
  
  module ModelInstanceMethods
    def amount_granted
      request_funding_sources.select{|rfs| rfs.request.granted}.inject(0){|acc, rfs| acc + (rfs.funding_amount || 0)}
    end
    
    def amount_remaining
      (amount || 0) - (amount_granted || 0)
    end

    def amount_granted_in_queue
      request_funding_sources.reject{|rfs| rfs.request.granted}.inject(0){|acc, rfs| acc + (rfs.funding_amount || 0)}
    end
    
    def derive_program
      if sub_initiative
        sub_initiative.initiative.sub_program.program if sub_initiative.initiative && sub_initiative.initiative.sub_program
      elsif initiative
        initiative.sub_program.program if initiative.sub_program
      elsif sub_program
        sub_program.program
      else
        program
      end
    end

    def derive_sub_program
      if sub_initiative
        sub_initiative.initiative.sub_program if sub_initiative.initiative
      elsif initiative
        initiative.sub_program
      else
        sub_program
      end
    end

    def derive_initiative
      if sub_initiative
        sub_initiative.initiative
      else
        initiative
      end
    end
    
    def derive_sub_initiative
      sub_initiative
    end
    
    # Only sub_initiative/initiative/sub_program/program is populated so we need to figure out which one is populated and derive from that
    def program_display_name
      obj = derive_program
      obj.name if obj
    end

    # Only sub_initiative/initiative/sub_program/program is populated so we need to figure out which one is populated and derive from that
    def sub_program_display_name
      obj = derive_sub_program
      obj.name if obj
    end

    def initiative_display_name
      obj = derive_initiative
      obj.name if obj
    end

    def sub_initiative_display_name
      sub_initiative.name if sub_initiative
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
    
    def funding_source_title request_amount=nil
      current_amount_remaining = self.amount_remaining
      funds_available = if request_amount
        if current_amount_remaining > request_amount
          "#{current_amount_remaining.to_currency} (#{amount_granted_in_queue.to_currency} in pipeline)"
        else
          "Less than #{request_amount.to_currency} available"
        end
      else
        "#{current_amount_remaining.to_currency} (#{amount_granted_in_queue.to_currency} in pipeline)"
      end
      "#{self.funding_source ? self.funding_source.name : ''}: #{funds_available}"
    end
    
    def autocomplete_to_s
      title
    end
  end
end