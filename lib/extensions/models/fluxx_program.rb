module FluxxProgram
  def self.included(base)
    base.acts_as_audited

    base.has_many :initiatives
    base.validates_presence_of     :name
    base.validates_length_of       :name,    :within => 3..255

    base.belongs_to :parent_program, :class_name => 'Program', :foreign_key => :parent_id
    base.has_many :children_programs, :class_name => 'Program', :foreign_key => :parent_id
    
    base.insta_search
    base.insta_export
    base.insta_realtime

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
      request_roles + grant_roles + finance_roles
    end

    def all_program_users
      RoleUser.includes(:user).where(:roleable_type => self.name).map{|ru| ru.user}
    end
  end

  module ModelInstanceMethods
    def load_initiatives minimum_fields=true
      select_field_sql = if minimum_fields
        'name, id, program_id'
      else
        'initiatives.*'
      end
      Initiative.find :all, :select => select_field_sql, :conditions => ['program_id = ?', id], :order => :name
    end

    def load_users
      UserRole.find_by_roleable self
    end

    def to_s
      name
    end
  end
end