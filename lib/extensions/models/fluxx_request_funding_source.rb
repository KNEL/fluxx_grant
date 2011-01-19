module FluxxRequestFundingSource
  SEARCH_ATTRIBUTES = [:request_id]

  def self.included(base)
    base.belongs_to :request
    base.belongs_to :funding_source_allocation
    base.has_many :request_transaction_funding_sources

    base.send :attr_accessor, :program
    base.send :attr_accessor, :program_id
    base.send :attr_accessor, :initiative
    base.send :attr_accessor, :initiative_id
    base.send :attr_accessor, :sub_program
    base.send :attr_accessor, :sub_program_id
    base.send :attr_accessor, :sub_initiative
    base.send :attr_accessor, :sub_initiative_id
    base.send :attr_accessor, :spending_year
    
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES
    end
    base.insta_export
    base.insta_multi
    base.insta_lock
    base.insta_realtime

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
    
    def amount_remaining
      funding_amount - request_transaction_funding_sources.inject(0){|acc, rtfs| acc - rtfs.amount}
    end
  end
end