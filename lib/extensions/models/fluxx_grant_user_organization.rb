module FluxxGrantUserOrganization
  def self.included(base)
    base.belongs_to :program, :class_name => 'Program', :foreign_key => :roleable_id  # So we can do a sphinx index
    base.send :include, ::FluxxUserOrganization
    base.after_commit :update_related_data
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def update_related_data
      p "ESH: 111 in UserOrganization update_related_data"
      if User.respond_to? :indexed_by_sphinx?
        p "ESH: 222 in UserOrganization update_related_data"
        User.without_realtime do
          p "ESH: 333 in UserOrganization update_related_data"
          if organization_id
            p "ESH: 444a in UserOrganization update_related_data"
            Organization.update_all 'delta = 1', ['id = ?', organization_id]
            p "ESH: 444b in UserOrganization update_related_data"
            o = Organization.find(organization_id)
            p "ESH: 444c in UserOrganization update_related_data"
            o.delta = 1
            p "ESH: 444d in UserOrganization update_related_data"
            o.save 
            p "ESH: 444e in UserOrganization update_related_data"
          end
        end
      end
    end
  end
end