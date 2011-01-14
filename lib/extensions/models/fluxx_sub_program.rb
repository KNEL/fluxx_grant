module FluxxSubProgram
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :program_id]
  
  def self.included(base)
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :program

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

    def load_initiatives minimum_fields=true
      select_field_sql = if minimum_fields
        'description, name, id, sub_program_id'
      else
        'initiative.*'
      end
      Initiative.find :all, :select => select_field_sql, :conditions => ['sub_program_id = ?', id], :order => :name
    end
    
    def funding_source_allocations options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      retired_clause = options[:show_retired] ? " retired != 1 or retired is null " : ''

      FundingSourceAllocation.find_by_sql(FundingSourceAllocation.send(:sanitize_sql, ["select funding_source_allocations.* from funding_source_allocations where 
        #{spending_year_clause}
        (sub_program_id = ?
          or initiative_id in (select initiatives.id from initiatives where sub_program_id = ?)
          or sub_initiative_id in (select sub_initiatives.id from sub_initiatives, initiatives where initiative_id = initiatives.id and sub_program_id = ?))", 
          self.id, self.id, self.id]))
    end
    
    
    def total_allocation options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      total_amount = FundingSourceAllocation.connection.execute(
          FundingSourceAllocation.send(:sanitize_sql, ["select sum(amount) from funding_source_allocations where 
            #{spending_year_clause}
            (sub_program_id = ?
              or initiative_id in (select initiatives.id from initiatives where sub_program_id = ?)
              or sub_initiative_id in (select sub_initiatives.id from sub_initiatives, initiatives where initiative_id = initiatives.id and sub_program_id = ?))", 
            self.id, self.id, self.id]))
      total_amount.fetch_row.first.to_i
    end
  end
end