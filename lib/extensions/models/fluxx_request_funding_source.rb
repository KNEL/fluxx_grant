module FluxxRequestFundingSource
  SEARCH_ATTRIBUTES = [:request_id]

  def self.included(base)
    base.belongs_to :request
    base.belongs_to :funding_source
    base.belongs_to :program
    base.belongs_to :initiative
    base.belongs_to :sub_program
    base.belongs_to :sub_initiative
    
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
  end
end