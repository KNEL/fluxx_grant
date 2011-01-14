module FluxxInitiative
  SEARCH_ATTRIBUTES = [:sub_program_id]
  def self.included(base)
    base.belongs_to :sub_program
    base.acts_as_audited

    base.validates_presence_of     :sub_program
    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..255
    
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
    
    def load_sub_initiatives minimum_fields=true
      select_field_sql = if minimum_fields
        'description, name, id, initiative_id'
      else
        'sub_initiatives.*'
      end
      SubInitiative.find :all, :select => select_field_sql, :conditions => ['initiative_id = ?', id], :order => :name
    end
    
    def funding_source_allocations options={}
      fsas = FundingSourceAllocation.where(:initiative_id => self.id, :deleted_at => nil)
      if options[:show_retired]
        fsas = fsas.where(["retired != ? or retired is null", 1])
      end
      if options[:spending_year]
        fsas = fsas.where(:spending_year => options[:spending_year])
      end
      fsas.all
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
  end
end