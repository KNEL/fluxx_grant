module FluxxInitiative
  SEARCH_ATTRIBUTES = [:program_id, :sub_program_id]
  LIQUID_METHODS = [:name]
    
  def self.included(base)
    base.belongs_to :sub_program
    base.acts_as_audited

    base.validates_presence_of     :sub_program
    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..255
    base.send :attr_accessor, :not_retired
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    base.insta_realtime
    base.insta_template do |insta|
      insta.entity_name = 'initiative'
      insta.add_methods []
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def load_all
      Initiative.where(:retired => 0).all
    end
  end

  module ModelInstanceMethods
    def autocomplete_to_s
      description || name
    end

    def to_s
      autocomplete_to_s
    end
    
    def load_sub_initiatives minimum_fields=true
      select_field_sql = if minimum_fields
        'description, name, id, initiative_id'
      else
        'sub_initiatives.*'
      end
      SubInitiative.find :all, :select => select_field_sql, :conditions => ['initiative_id = ?', id], :order => :name
    end
    
    def program_id= program_id
      # no-op to make the form happy ;)
    end
    
    def program_id
      program.id if program
    end
    
    def program
      sub_program.program if sub_program
    end

    def funding_source_allocations options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      retired_clause = options[:show_retired] ? " retired != 1 or retired is null " : ''

      FundingSourceAllocation.find_by_sql(FundingSourceAllocation.send(:sanitize_sql, ["select funding_source_allocations.* from funding_source_allocations where 
        #{spending_year_clause}
        (initiative_id = ?
          or sub_initiative_id in (select sub_initiatives.id from sub_initiatives where initiative_id = ?)) and funding_source_allocations.deleted_at is null",
          self.id, self.id]))
    end

    def total_allocation options={}
      spending_year_clause = options[:spending_year] ? " spending_year = #{options[:spending_year]} and " : ''
      total_amount = FundingSourceAllocation.connection.execute(
          FundingSourceAllocation.send(:sanitize_sql, ["select sum(amount) from funding_source_allocations where 
            #{spending_year_clause}
            (initiative_id = ?
              or sub_initiative_id in (select sub_initiatives.id from sub_initiatives where initiative_id = ?)) and funding_source_allocations.deleted_at is null", 
            self.id, self.id]))
      total_amount.fetch_row.first.to_i
    end
  end
end