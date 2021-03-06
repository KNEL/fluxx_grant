module FluxxFundingSource
  def self.included(base)
    base.has_many :request_funding_sources
    base.has_many :funding_source_allocations, :conditions => {:deleted_at => nil}
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.acts_as_audited

    base.insta_search
    base.insta_export
    base.insta_realtime
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def amount= new_amount
      write_attribute(:amount, filter_amount(new_amount))
    end
    
    def amount_available
      funding_source_allocations.inject(amount || 0){|acc, fsa| acc - (fsa.amount || 0)}
    end
  end
end