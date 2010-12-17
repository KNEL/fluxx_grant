module FluxxSubProgram
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

    def to_s
      autocomplete_to_s
    end

    def load_sub_initiatives minimum_fields=true
      select_field_sql = if minimum_fields
        'description, name, id, sub_program_id'
      else
        'sub_initiative.*'
      end
      SubInitiative.find :all, :select => select_field_sql, :conditions => ['sub_program_id = ?', id], :order => :name
    end
  end
end