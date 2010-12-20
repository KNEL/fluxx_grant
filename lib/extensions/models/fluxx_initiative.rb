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
    
    def funding_source_allocations show_retired=false
      fsas = FundingSourceAllocation.where(:initiative_id => self.id)
      unless show_retired 
        fsas = fsas.where(["retired != ? or retired is null", 1])
      end
      fsas.all
    end
  end
end