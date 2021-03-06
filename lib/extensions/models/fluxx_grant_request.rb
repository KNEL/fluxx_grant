module FluxxGrantRequest
  def self.included(base)
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :modified_by_id, :locked_until, :locked_by_id, :delta, :updated_by, :created_by, :audits]})

    # NOTE: for STI classes such as GrantRequest, the polymorphic associations must be replicated to get the correct class...
    base.has_many :workflow_events, :foreign_key => :workflowable_id, :conditions => {:workflowable_type => base.name}
    base.has_many :favorites, :foreign_key => :favorable_id, :conditions => {:favorable_type => base.name}
    base.has_many :notes, :foreign_key => :notable_id, :conditions => {:notable_type => base.name}
    base.has_many :group_members, :foreign_key => :groupable_id, :conditions => {:groupable_type => base.name}
    base.has_many :model_documents, :foreign_key => :documentable_id, :conditions => {:documentable_type => base.name}
    base.has_many :wiki_documents, :foreign_key => :model_id, :conditions => {:model_type => base.name}
    
    base.validates_presence_of     :program_organization
    base.validates_presence_of     :program
    base.validates_presence_of     :project_summary
    base.validates_presence_of     :duration_in_months, :if => :state_after_pre_recommended_chain
    base.validates_presence_of     :amount_requested
    base.validates_presence_of     :amount_recommended, :if => :state_after_pre_recommended_chain
    base.validates_associated      :program_organization
    base.validates_associated      :program

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def generate_grant_transactions
      interim_request_document = request_reports.select{|rep| rep.is_interim_type?}.last
      final_request_document = request_reports.select{|rep| rep.is_final_type?}.last
      if self.is_er?
        if program_organization.grants.size > 0 # Is there another grant that already exists
          # Transactions for ER trusted orgs
          if duration_in_months > 12
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,
              :amount_due => amount_recommended * 0.5, :due_at => grant_agreement_at, :state => 'due')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,
              :amount_due => amount_recommended * 0.4, :due_at => interim_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'interim_request')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.1,:due_at => final_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'final_request')
          else
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,  
              :amount_due => amount_recommended * 0.9, :due_at => grant_agreement_at, :state => 'due')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.1,:due_at => final_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'final_request')
          end
        else
          # Transactions for ER non-trusted orgs
          if duration_in_months > 12
            raise I18n.t(:er_grants_may_not_be_greater_than_one_year, :duration_in_months => duration_in_months)
          else
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.6, :due_at => grant_agreement_at, :state => 'due')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.3,:due_at => interim_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'interim_request')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,
              :amount_due => amount_recommended * 0.1,:due_at => final_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'final_request')
          end
        end
      else
        # Transactions for public charities
        if duration_in_months > 12
          request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, :amount_due => amount_recommended * 0.5, 
            :due_at => grant_agreement_at, :state => 'due')
          request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, :amount_due => amount_recommended * 0.5, 
            :due_at => interim_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'interim_request')
        else
          request_transactions << RequestTransaction.new(:request_id => self.id, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, :amount_due => amount_recommended, 
            :due_at => grant_agreement_at, :state => 'due')
        end
      end
    end
    
    def generate_grant_reports
      new_grantee = program_organization.grants.select {|grant| grant.id != self.id}.empty?
      # Interim Reports
      if duration_in_months > 12
        request_reports << RequestReport.new(:request => self, :due_at => (grant_begins_at + 10.months).next_business_day, :report_type => RequestReport.interim_budget_type_name)
        request_reports << RequestReport.new(:request => self, :due_at => (grant_begins_at + 10.months).next_business_day, :report_type => RequestReport.interim_narrative_type_name)
      elsif new_grantee
        request_reports << RequestReport.new(:request => self, :due_at => (grant_begins_at + (grant_ends_at - grant_begins_at) / 2).next_business_day, :report_type => RequestReport.interim_budget_type_name)
        request_reports << RequestReport.new(:request => self, :due_at => (grant_begins_at + (grant_ends_at - grant_begins_at) / 2).next_business_day, :report_type => RequestReport.interim_narrative_type_name)
      end
      interim_request_document = request_reports.last

      # Final Reports
      if self.is_er?
        request_reports << RequestReport.new(:request => self, :due_at => (grant_ends_at + 1.month).next_business_day, :report_type => RequestReport.final_budget_type_name)
        request_reports << RequestReport.new(:request => self, :due_at => (grant_ends_at + 1.month).next_business_day, :report_type => RequestReport.final_narrative_type_name)
      else
        request_reports << RequestReport.new(:request => self, :due_at => (grant_ends_at + 2.month).next_business_day, :report_type => RequestReport.final_budget_type_name)
        request_reports << RequestReport.new(:request => self, :due_at => (grant_ends_at + 2.month).next_business_day, :report_type => RequestReport.final_narrative_type_name)
      end
      final_request_document = request_reports.last

      # Eval Reports
      eval_request_document = RequestReport.new(:request => self, :due_at => (final_request_document.due_at + 1.month).next_business_day, :report_type => RequestReport.eval_type_name)
      request_reports << eval_request_document
    end

    # This will generate (but not persist to DB) all the transactions, etc. necessary to make the grant go through
    def generate_grant_details
      generate_grant_dates
      generate_grant_reports
      generate_grant_transactions
      generate_charity_check

      # award_letter_template = LetterTemplate.find :first, :conditions => ['letter_type = ?', 'AwardLetterTemplate']
      # ga_letter_template = LetterTemplate.find :first, :conditions => ['letter_type = ?', 'GrantAgreementTemplate']
      # award_letter = RequestLetter.create :request => self, :letter_template => award_letter_template, :letter => award_letter_template.letter
      # ga_letter = RequestLetter.create :request => self, :letter_template => ga_letter_template, :letter => ga_letter_template.letter
    end
    
    def generate_charity_check
      tax_class_org.update_charity_check
    end

    def org_name_text
      org_name = if program_organization
        program_organization.display_name.strip if program_organization.display_name
      end || ''
      fiscal_org_name = if fiscal_organization && program_organization != fiscal_organization
        ", a project of #{fiscal_organization.display_name.strip if fiscal_organization.display_name}"
      end || ''
      org_name + fiscal_org_name
    end
  end
end
