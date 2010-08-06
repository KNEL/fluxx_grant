module FluxxRequestFundingSource
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :funding_source
    base.belongs_to :program
    base.belongs_to :initiative
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def funding_amount= new_amount
      write_attribute(:funding_amount, filter_amount(new_amount))
    end
  end
end