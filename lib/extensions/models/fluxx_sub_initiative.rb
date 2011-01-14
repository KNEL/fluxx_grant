module FluxxSubInitiative
  SEARCH_ATTRIBUTES = [:created_at, :updated_at, :id, :initiative_id]
  
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

    def funding_source_allocations options={}
      fsas = FundingSourceAllocation.where(:sub_initiative_id => self.id, :deleted_at => nil)
      if options[:show_retired]
        fsas = fsas.where(["retired != ? or retired is null", 1])
      end
      if options[:spending_year]
        fsas = fsas.where(:spending_year => options[:spending_year])
      end
      fsas.all
    end

    def to_s
      autocomplete_to_s
    end
    
    def program_id
      program.id if program
    end
    
    def program
      sub_program.program if sub_program
    end
    
    def sub_program_id
      sub_program.id if sub_program
    end
    
    def sub_program
      initiative.sub_program if initiative
    end
  end
end