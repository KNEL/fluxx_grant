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
    ITEMS_PER_PAGE = 10
    def index
      # TODO: Use fiscal_organization_id
      # TODO: Unexpected results from query
      org_ids = [23, 6347]

      client_store = ClientStore.where(:user_id => fluxx_current_user.id, :client_store_type => 'grantee portal').first || 
                     ClientStore.create(:user_id => fluxx_current_user.id, :client_store_type => 'grantee portal', :data => {:pages => {:requests => 1, :grants => 1, :reports => 1, :transactions => 1}}.to_json, :name => "Default")
      
      settings = client_store.data.de_json
      
      all = !params[:requests] && !params[:grants] && ! params[:reports] && !params[:transactions]
      table = params[:table] ? (["requests", "grants", "reports", "transactions"].index(params[:table]) ? params[:table] : :all) : :all
      page = params[:page] ? params[:page] : settings["pages"][table]      
      settings["pages"][table] = page if (table != :all)
  
      requests = Request.search '', :with => {:program_organization_id => org_ids, :deleted_at => 0, :filter_type => "GrantRequest".to_crc32}, :order => "updated_at desc"
      request_ids = requests.map { |request| request.id }
      
      puts
      
      if table == :all || table == "requests"
        @requests = requests.select{|request| request[:granted] == false}.paginate :page => settings["pages"]["requests"], :per_page => ITEMS_PER_PAGE
        @title = "Requests"
        template = "_grant_request_list"
      end
      
      if table == :all || table == "grants"
        @grants = requests.select{|request| request[:granted] == true}.paginate :page => settings["pages"]["grants"], :per_page => ITEMS_PER_PAGE
        @title = "Grants"
        template = "_grant_request_list"
      end
      
      if table == :all || table == "reports"
        @reports = RequestReport.where(:request_id => request_ids).order("updated_at desc").paginate :page => settings["pages"]["reports"], :per_page => ITEMS_PER_PAGE
        template = "_report_list"
      end
      
      if table == :all || table == "transactions"
        @transactions = RequestTransaction.where(:request_id => request_ids).order("updated_at desc").paginate :page => settings["pages"]["transactions"], :per_page => ITEMS_PER_PAGE
        template = "_transaction_list"
      end      
      
      if table != :all                
        client_store.data = settings.to_json
        client_store.save
        @data = @requests || @grants || @reports || @transactions
        render template, :layout => false
      end
    end
    
  end
end