module FluxxGrantRequest
  def self.included(base)
    base.acts_as_audited({:full_model_enabled => true, :except => [:created_by_id, :updated_by_id, :locked_until, :locked_by_id, :delta], :protect => true})

    # NOTE: for STI classes such as GrantRequest, the polymorphic associations must be replicated to get the correct class...
    base.has_many :workflow_events, :foreign_key => :workflowable_id, :conditions => {:workflowable_type => base.name}
    base.has_many :favorites, :foreign_key => :favorable_id, :conditions => {:favorable_type => base.name}
    base.has_many :notes, :foreign_key => :notable_id, :conditions => {:notable_type => base.name}
    base.has_many :group_members, :foreign_key => :groupable_id, :conditions => {:groupable_type => base.name}
    
    base.validates_presence_of     :program_organization
    base.validates_presence_of     :program
    base.validates_presence_of     :project_summary
    base.validates_presence_of     :duration_in_months, :if => :state_after_pre_recommended_chain
    base.validates_presence_of     :amount_requested
    base.validates_presence_of     :amount_recommended, :if => :state_after_pre_recommended_chain
    base.validates_associated      :program_organization
    base.validates_associated      :program

    # AASM doesn't deal with inheritance of active record models quite the way we need here.  Grab Request's state machine as a starting point and modify.
    # AASM::StateMachine[GrantRequest] = AASM::StateMachine[Request].clone
    
    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    # This will generate (but not persist to DB) all the transactions, etc. necessary to make the grant go through
    def generate_grant_details
      p "ESH: in generate_grant_details"
      generate_grant_dates

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

      if self.is_er?
        p "ESH: 111 yes, it is ER"
        if program_organization.grants.size > 0 # Is there another grant that already exists
          p "ESH: 222 yes, a grant already exists"
          # Transactions for ER trusted orgs
          if duration_in_months > 12
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,
              :amount_due => amount_recommended * 0.5, :due_at => grant_agreement_at, :state => 'actually_due')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,
              :amount_due => amount_recommended * 0.4, :due_at => interim_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'interim_request')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.1,:due_at => final_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'final_request')
          else
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id,  
              :amount_due => amount_recommended * 0.9, :due_at => grant_agreement_at, :state => 'actually_due')
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.1,:due_at => final_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'final_request')
          end
        else
          p "ESH: 333 no, a grant does not already exist"
          # Transactions for ER non-trusted orgs
          if duration_in_months > 12
            raise I18n.t(:er_grants_may_not_be_greater_than_one_year, :duration_in_months => duration_in_months)
          else
            request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, 
              :amount_due => amount_recommended * 0.6, :due_at => grant_agreement_at, :state => 'actually_due')
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
            :due_at => grant_agreement_at, :state => 'actually_due')
          request_transactions << RequestTransaction.new(:request => self, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, :amount_due => amount_recommended * 0.5, 
            :due_at => interim_request_document.due_at, :state => 'tentatively_due', :request_document_linked_to => 'interim_request')
        else
          request_transactions << RequestTransaction.new(:request_id => self.id, :created_by_id => self.updated_by_id, :updated_by_id => self.updated_by_id, :amount_due => amount_recommended, 
            :due_at => grant_agreement_at, :state => 'actually_due')
        end
      end


      # award_letter_template = LetterTemplate.find :first, :conditions => ['letter_type = ?', 'AwardLetterTemplate']
      # ga_letter_template = LetterTemplate.find :first, :conditions => ['letter_type = ?', 'GrantAgreementTemplate']
      # award_letter = RequestLetter.create :request => self, :letter_template => award_letter_template, :letter => award_letter_template.letter
      # ga_letter = RequestLetter.create :request => self, :letter_template => ga_letter_template, :letter => ga_letter_template.letter
    end

    def org_name_text
      org_name = if program_organization
        program_organization.name.strip if program_organization.name
      end || ''
      fiscal_org_name = if fiscal_organization && program_organization != fiscal_organization
        ", a project of #{fiscal_organization.name.strip if fiscal_organization.name}"
      end || ''
      org_name + fiscal_org_name
    end
  end
end