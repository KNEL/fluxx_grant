module FluxxRequestTransaction
  def self.prepare_from_date search_with_attributes, name, val
    if (Time.parse(val) rescue nil)
      start_at = Time.parse(val)
      if search_with_attributes[name] && search_with_attributes[name].end < FAR_IN_THE_FUTURE
        search_with_attributes[name] = (start_at.to_i..(search_with_attributes[name].end))
      else
        search_with_attributes[name] = (start_at.to_i..FAR_IN_THE_FUTURE.to_i)
      end
      search_with_attributes
    end || {}
  end
  
  def self.prepare_to_date search_with_attributes, name, val
    if (Time.parse(val) rescue nil)
      end_at = Time.parse(val)
      if search_with_attributes[name] && search_with_attributes[name].begin > 0
        search_with_attributes[name] = ((search_with_attributes[name].begin)..end_at.to_i)
      else
        search_with_attributes[name] = (0..end_at.to_i)
      end
      search_with_attributes
    end || {}
  end

  SEARCH_ATTRIBUTES = [:grant_program_ids, :grant_sub_program_ids, :state, :updated_at, :request_type, :amount_paid, :favorite_user_ids, :has_been_paid, :filter_state]
  FAR_IN_THE_FUTURE = Time.now + 1000.year
  LIQUID_METHODS = [:amount_due, :due_at]
  
  def self.included(base)
    base.belongs_to :request
    base.belongs_to :grant, :class_name => 'GrantRequest', :foreign_key => 'request_id', :conditions => {:granted => 1}
    base.belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
    base.belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'
    base.belongs_to :payment_recorded_by, :class_name => 'User', :foreign_key => 'payment_recorded_by_id'
    base.belongs_to :user_payee, :class_name => 'User', :foreign_key => 'user_payee_id'
    base.belongs_to :organization_payee, :class_name => 'Organization', :foreign_key => 'organization_payee_id'
    base.has_many :request_transaction_funding_sources
    base.has_many :workflow_events, :as => :workflowable
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})
    base.has_many :model_documents, :as => :documentable
    base.has_many :notes, :as => :notable, :conditions => {:deleted_at => nil}
    base.has_many :group_members, :as => :groupable
    base.has_many :groups, :through => :group_members
    base.send :attr_accessor, :organization_lookup
    base.belongs_to :bank_account
    
    base.insta_favorite
    base.insta_export do |insta|
      insta.filename = 'request_transaction'
      insta.headers = [['Date Created', :date], ['Date Updated', :date], 'request_id', ['Amount Paid', :currency], ['Amount Due', :currency], ['Date Due', :date], ['Date Paid', :date], 'payment_type', 'payment_confirmation']
      insta.sql_query = "select rt.created_at, rt.updated_at, requests.base_request_id request_id, amount_paid, amount_due, due_at, paid_at, payment_type, payment_confirmation_number
                from request_transactions rt
                left outer join requests on rt.request_id = requests.id
                where rt.id IN (?)"
    end
    base.insta_search do |insta|
      insta.filter_fields = SEARCH_ATTRIBUTES  + [:group_ids, :due_in_days, :overdue_by_days, :lead_user_ids, :grant_multi_element_value_ids, :request_from_date, :request_to_date]
      insta.derived_filters = {:due_in_days => (lambda do |search_with_attributes, request_params, name, value|
        value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now + value.to_i.days
            search_with_attributes[:due_at] = (0..due_date_check.to_i)
            search_with_attributes[:has_been_paid] = false
          end || {}
        end),
        :overdue_by_days => (lambda do |search_with_attributes, request_params, name, value|
          value = value.first if value && value.is_a?(Array)
          if value.to_s.is_numeric?
            due_date_check = Time.now - value.to_i.days
            search_with_attributes[:due_at] = (0..due_date_check.to_i)
            search_with_attributes[:has_been_paid] = false
          end || {}
        end),
        :request_from_date => (lambda do |search_with_attributes, request_params, name, val|
          val = val.first if val && val.is_a?(Array)
          date_range_selector = request_params[:request_transaction][:date_range_selector] if request_params[:request_transaction]
          date_range_selector = request_params[:date_range_selector] unless date_range_selector
          case date_range_selector
          when 'due_at' then
            prepare_from_date search_with_attributes, :due_at, val
          when 'paid_at' then
            prepare_from_date search_with_attributes, :paid_at, val
          end
        end),
        :request_to_date => (lambda do |search_with_attributes, request_params, name, val|
          val = val.first if val && val.is_a?(Array)
          date_range_selector = request_params[:request_transaction][:date_range_selector] if request_params[:request_transaction]
          date_range_selector = request_params[:date_range_selector] unless date_range_selector
          case date_range_selector
          when 'due_at' then
            prepare_to_date search_with_attributes, :due_at, val
          when 'paid_at' then
            prepare_to_date search_with_attributes, :paid_at, val
          end
        end),
        :grant_program_ids => (lambda do |search_with_attributes, request_params, name, val|
          program_id_strings = val
          programs = program_id_strings.map {|pid| Program.find pid rescue nil}.compact
          program_ids = programs.map do |program| 
            children = program.children_programs
            if children.empty?
              program
            else
              children
            end
          end.compact.flatten.map &:id
          search_with_attributes[:grant_program_ids] = program_ids if program_ids && !program_ids.empty?
        end),
        }
    end
    base.insta_realtime do |insta|
      insta.delta_attributes = SEARCH_ATTRIBUTES
      insta.updated_by_field = :updated_by_id
    end
    base.insta_multi
    base.insta_lock
    base.insta_utc do |insta|
      insta.time_attributes = [:due_at, :paid_at, :transaction_at] 
    end
    
    base.insta_workflow do |insta|
      insta.add_state_to_english :due, 'Due'
      insta.add_state_to_english :paid, 'Paid'
      insta.add_state_to_english :new, 'New'
      
      insta.add_event_to_english :mark_paid, 'Record Payment'      
    end
    
    base.insta_template do |insta|
      insta.entity_name = 'request_transaction'
      insta.add_methods []
      insta.remove_methods [:id]
    end
    base.liquid_methods *( LIQUID_METHODS )

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
    
    base.send :include, AASM
    base.add_aasm
    base.add_sphinx if base.respond_to?(:sphinx_indexes) && !(base.connection.adapter_name =~ /SQLite/i)
  end

  module ModelClassMethods
    def add_sphinx
      define_index :request_transaction_first do
        # fields
        indexes request.program_organization.name, :as => :request_org_name, :sortable => true
        indexes request.program_organization.acronym, :as => :request_org_acronym, :sortable => true
        indexes "if(requests.type = 'FipRequest', concat('FG-',requests.base_request_id), concat('G-',requests.base_request_id))", :as => :request_grant_id, :sortable => true

        # attributes
        has created_at, updated_at, deleted_at, due_at, paid_at, amount_paid, amount_due
        set_property :delta => :delayed
        has :state, :type => :string, :crc => true, :as => :filter_state
        has grant.state, :type => :string, :crc => true, :as => :grant_state
        has grant(:id), :as => :grant_ids
        has grant.program(:id), :as => :grant_program_ids
        has grant.sub_program(:id), :as => :grant_sub_program_ids
        has request(:type), :type => :string, :crc => true, :as => :request_type
        has "IF(request_transactions.state = 'paid' OR (paid_at IS NOT NULL AND amount_paid IS NOT NULL), 1, 0)", :as => :has_been_paid, :type => :boolean
        has "CONCAT(IFNULL(`requests`.`program_organization_id`, '0'), ',', IFNULL(`requests`.`fiscal_organization_id`, '0'))", :as => :related_organization_ids, :type => :multi
        has grant.multi_element_choices.multi_element_value_id, :type => :multi, :as => :grant_multi_element_value_ids
        # TODO ESH: derive the following which are no longer basd on roles_users but instead on program_lead_requests, grantee_org_owner_requests, grantee_signatory_requests, fiscal_org_owner_requests, fiscal_signatory_requests
        # has request.lead_user_roles.roles_users.user(:id), :as => :lead_user_ids
        has group_members.group(:id), :type => :multi, :as => :group_ids
        has favorites.user(:id), :as => :favorite_user_ids
      end
    end

    def mark_paid
      'mark_paid'
    end

    def add_aasm
      aasm_column :state
      aasm_initial_state :new

      aasm_state :new
      aasm_state :due
      aasm_state :paid

      aasm_event :mark_paid do
        transitions :from => :new, :to => :paid
        transitions :from => :due, :to => :paid
      end
    end
    
    def document_title_name
      "Invoice"
    end
  end

  module ModelInstanceMethods
    def state_to_english
      RequestTransaction.state_to_english_translation state
    end

    def has_been_paid
      state == 'paid' || (paid_at && amount_paid)
    end

    def title
      "Request Transaction of #{amount_due.to_currency :precision => 0} for #{request.grant_id}" if amount_due && request
    end

    def filter_state
      self.state
    end

    def request_type
      request.type if request
    end

    def grant_program_ids
      if request && request.program
        [request.program.id]
      else
        []
      end
    end

    def grant_sub_program_ids
      if request && request.sub_program
        [request.sub_program.id]
      else
        []
      end
    end

    def amount_paid= new_amount
      write_attribute(:amount_paid, filter_amount(new_amount))
    end

    def amount_due= new_amount
      write_attribute(:amount_due, filter_amount(new_amount))
    end
    
    def related_users
      if request
        request.related_users
      end || []
    end
    
    def related_organizations
      if request
        request.related_organizations
      end || []
    end
    
    def related_grants
      [request]
    end
    
    def related_transactions
      if request
        request.related_request_transactions - [self]
      end || []
    end
  end
end