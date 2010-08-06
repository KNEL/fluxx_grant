module FluxxRequestLetter
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :letter_template
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta], :protect => true})
    base.define_index do
      # fields
      indexes letter, :sortable => true

      # attributes
      has created_at, request_id, letter_template_id
      set_property :delta => true
    end
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def description
      letter_template.description if letter_template
    end
  end
end