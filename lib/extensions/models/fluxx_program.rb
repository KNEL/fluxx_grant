module FluxxProgram
  def self.included(base)
    base.acts_as_audited

    base.has_many :sub_programs
    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..255

    base.belongs_to :parent_program, :class_name => 'Program', :foreign_key => :parent_id
    base.has_many :children_programs, :class_name => 'Program', :foreign_key => :parent_id
    
    base.insta_search
    base.insta_export
    base.insta_realtime
    base.insta_multi
    base.insta_template do |insta|
      insta.entity_name = 'program'
      insta.add_methods []
      insta.remove_methods [:id]
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
    def finance_administrator_role_name
      'Finance Administrator'
    end

    def grants_administrator_role_name
      'Grants Administrator'
    end

    def grants_assistant_role_name
      'Grants Assistant'
    end

    def president_role_name
      'President'
    end

    def program_associate_role_name
      'Program Associate'
    end

    def program_director_role_name
      'Program Director'
    end

    def program_officer_role_name
      'Program Officer'
    end

    def cr_role_name
      'CR'
    end

    def svp_role_name
      'SVP'
    end

    def request_roles
      [president_role_name, program_associate_role_name, program_officer_role_name, program_director_role_name, cr_role_name, svp_role_name, grants_administrator_role_name, grants_assistant_role_name]
    end

    def grant_roles
      [grants_administrator_role_name, grants_assistant_role_name]
    end

    def finance_roles
      [finance_administrator_role_name]
    end
    
    def all_role_names
      (request_roles + grant_roles + finance_roles).uniq
    end

    def all_program_users
      User.joins(:role_users).where({:role_users => {:roleable_type => self.name}}).group("users.id").compact
    end

    def load_all
      Program.where(:retired => 0).all
    end
  end

  module ModelInstanceMethods
    
    def load_sub_programs minimum_fields=true
      select_field_sql = if minimum_fields
        'description, name, id, program_id'
      else
        'sub_programs.*'
      end
      SubProgram.find :all, :select => select_field_sql, :conditions => ['program_id = ?', id], :order => :name
    end

    def load_users role_name=nil
      user_query = User.joins(:role_users).where({:test_user_flag => 0, :role_users => {:roleable_type => self.class.name, :roleable_id => self.id}})
      user_query = user_query.where({:role_users => {:name => role_name}}) if role_name
      user_query.group("users.id").compact
    end
    
    def funding_source_allocations options={}
      fsas = FundingSourceAllocation.where(:program_id => self.id, :deleted_at => nil)
      if options[:show_retired]
        fsas = fsas.where(["retired != ? or retired is null", 1])
      end
      if options[:spending_year]
        fsas = fsas.where(:spending_year => options[:spending_year])
      end
      fsas.all
    end
    
    def autocomplete_to_s
      description || name
    end

    def to_s
      autocomplete_to_s
    end
  end
end