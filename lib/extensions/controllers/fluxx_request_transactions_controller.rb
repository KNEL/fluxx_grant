module FluxxRequestTransactionsController
  ICON_STYLE = 'style-transactions'
  def self.included(base)
    base.insta_index RequestTransaction do |insta|
      insta.template = 'request_transaction_list'
      insta.filter_title = "Transactions Filter"
      insta.filter_template = 'request_transactions/request_transaction_filter'
      insta.order_clause = 'due_at desc'
      insta.icon_style = ICON_STYLE
    end
    base.insta_show RequestTransaction do |insta|
      insta.template = 'request_transaction_show'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        # You should not be able to edit or delete transactions
        # instance_variable_set '@edit_enabled', false
        instance_variable_set '@delete_enabled', false
      end
    end
    base.insta_new RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.icon_style = ICON_STYLE
      insta.pre do |conf|
        request = Request.safe_find(grab_param(:request_transaction, :request_id))
        self.pre_model = RequestTransaction.new(:request => request)
      end
    end
    base.insta_edit RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.icon_style = ICON_STYLE
    end
    base.insta_post RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.icon_style = ICON_STYLE
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        update_transaction_funding_sources model if outcome == :success
      end
    end
    base.insta_put RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.icon_style = ICON_STYLE
      insta.add_workflow
      insta.post do |triple|
        controller_dsl, model, outcome = triple
        update_transaction_funding_sources model if outcome == :success
      end
    end
    base.insta_delete RequestTransaction do |insta|
      insta.template = 'request_transaction_form'
      insta.icon_style = ICON_STYLE
    end

    base.insta_role RequestReport do |insta|
      # Define who is allowd to perform which events
      insta.add_event_roles RequestTransaction.mark_paid, Program, Program.grant_roles + Program.finance_roles

      insta.extract_related_object do |model|
        model.request.program if model.request
      end
    end

    base.insta_related RequestTransaction do |insta|
      insta.add_related do |related|
        related.display_name = 'People'
        related.for_search do |model|
          model.related_users
        end
        related.add_title_block do |model|
          model.full_name if model
        end
        related.display_template = '/users/related_users'
      end
      insta.add_related do |related|
        related.display_name = 'Orgs'
        related.for_search do |model|
          model.related_organizations
        end
        related.add_title_block do |model|
          model.name if model
        end
        related.display_template = '/organizations/related_organization'
      end
      insta.add_related do |related|
        related.display_name = 'Grants'
        related.for_search do |model|
          model.related_grants
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.add_model_url_block do |model|
          send :granted_request_path, :id => model.id
        end
        related.display_template = '/grant_requests/related_request'
      end
      insta.add_related do |related|
        related.display_name = 'Trans'
        related.for_search do |model|
          model.related_transactions
        end
        related.add_title_block do |model|
          model.title if model
        end
        related.display_template = '/request_transactions/related_request_transactions'
      end
    end

    base.extend(ModelClassMethods)
    base.class_eval do
      include ModelInstanceMethods
    end
  end

  module ModelClassMethods
  end

  module ModelInstanceMethods
    def update_transaction_funding_sources model
      model.request.request_funding_sources.each do |rfs|
        amount = params["funding_source_value_#{rfs.id}"]
        p "ESH: 111 have an amount of #{amount} for rfs=#{rfs.id}"
        rtfs = RequestTransactionFundingSource.where(:request_transaction_id => model.id, :request_funding_source_id => rfs.id).first
        if !amount.blank?
          if rtfs
            p "ESH: 222 updating amount to #{amount} for rfs=#{rfs.id}"
            rtfs.update_attributes :amount => amount, :updated_by_id => current_user.id
          else
            p "ESH: 333 creating amount to #{amount} for rfs=#{rfs.id}"
            RequestTransactionFundingSource.create :request_transaction_id => model.id, :request_funding_source_id => rfs.id, :amount => amount, :created_by_id => current_user.id, :updated_by_id => current_user.id
          end
        elsif rtfs
          # The user removed the value, let's delete the record as well
          p "ESH: 444 user destroyed rfs=#{rfs.id}"
          rtfs.destroy
        end
      end
    end
  end
end