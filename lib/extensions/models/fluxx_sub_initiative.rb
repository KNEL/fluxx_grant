module FluxxSubInitiative
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :program_id, :sub_program_id, :initiative_id]
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :initiative

    base.acts_as_audited({:full_model_enabled => false, :except => [:created_by_id, :updated_by_id, :delta, :updated_by, :created_by, :audits]})

    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
      insta.derived_filters = {}
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end
  
  module ModelInstanceMethods
    def autocomplete_to_s
      description || name
    end

    def to_s
      autocomplete_to_s
    end
    
    def program_id
      program.id if program
    end
    def program_id= program_id
      # no-op to make the form happy ;)
    end
    
    def program
      sub_program.program if sub_program
    end
    
    def sub_program_id
      sub_program.id if sub_program
    end
    def sub_program_id= sub_program_id
      # no-op to make the form happy ;)
    end
    
    def sub_program
      initiative.sub_program if initiative
    end

    def funding_source_allocations options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      retired_clause = options[:show_retired] ? " retired != 1 or retired is null " : ''

      FundingSourceAllocation.find_by_sql(FundingSourceAllocation.send(:sanitize_sql, ["select funding_source_allocations.* from funding_source_allocations where 
            #{spending_year_clause}
            (sub_initiative_id = ?)", 
            self.id]))
    end

    def total_allocation options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      total_amount = FundingSourceAllocation.connection.execute(
          FundingSourceAllocation.send(:sanitize_sql, ["select sum(amount) from funding_source_allocations where 
            #{spending_year_clause}
            (sub_initiative_id = ?)", 
            self.id]))
      total_amount.fetch_row.first.to_i
    end
  end
end