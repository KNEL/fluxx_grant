module FluxxGranteePortalController
  def self.included(base)
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def index
      org_ids = [6347, 23]
      @requests = Request.search '', :with => {:program_organization_id => org_ids}
      @grants = GrantRequest.search '', :with => {:program_organization_id => org_ids}
      request_ids = (@requests.map { |request| request.id }) + (@grants.map { |grant| grant.id })
      @reports = RequestReport.where(:request_id => request_ids)
      @transactions = RequestTransaction.where(:request_id => request_ids)
    end
  end
end