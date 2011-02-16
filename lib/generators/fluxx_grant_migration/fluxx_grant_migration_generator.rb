require 'rails/generators'
require 'rails/generators/migration'

class FluxxGrantMigrationGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  def self.source_root
    File.join(File.dirname(__FILE__), 'templates')
  end

  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end
  
  def create_geo_tables
    handle_migration 'create_programs.rb', 'db/migrate/fluxx_grant_create_programs.rb'
    handle_migration 'create_funding_sources.rb', 'db/migrate/fluxx_grant_create_funding_sources.rb'
    handle_migration 'create_initiatives.rb', 'db/migrate/fluxx_grant_create_initiatives.rb'
    handle_migration 'create_letter_templates.rb', 'db/migrate/fluxx_grant_create_letter_templates.rb'
    handle_migration 'create_requests.rb', 'db/migrate/fluxx_grant_create_requests.rb'
    handle_migration 'create_request_letters.rb', 'db/migrate/fluxx_grant_create_request_letters.rb'
    handle_migration 'create_request_organizations.rb', 'db/migrate/fluxx_grant_create_request_organizations.rb'
    handle_migration 'create_request_reports.rb', 'db/migrate/fluxx_grant_create_request_reports.rb'
    handle_migration 'create_request_transactions.rb', 'db/migrate/fluxx_grant_create_request_transactions.rb'
    handle_migration 'create_request_funding_sources.rb', 'db/migrate/fluxx_grant_create_request_funding_sources.rb'
    handle_migration 'create_request_users.rb', 'db/migrate/fluxx_grant_create_request_users.rb'
    handle_migration 'create_request_geo_states.rb', 'db/migrate/fluxx_grant_create_request_geo_states.rb'
    handle_migration 'add_grant_fields_to_organization.rb', 'db/migrate/fluxx_grant_add_grant_fields_to_organization.rb'
    handle_migration 'create_request_evaluation_metrics.rb', 'db/migrate/fluxx_grant_create_request_evaluation_metrics.rb'
    handle_migration 'create_project_requests.rb', 'db/migrate/fluxx_grant_create_project_requests.rb'
    handle_migration 'drop_request_letters.rb', 'db/migrate/fluxx_grant_drop_request_letters.rb'
    handle_migration 'add_description_to_project_relationships.rb', 'db/migrate/fluxx_grant_add_description_to_project_relationships.rb'
    handle_migration 'add_board_authority_to_request_funding_source.rb', 'db/migrate/fluxx_grant_add_board_authority_to_request_funding_source.rb'
    handle_migration 'create_sub_program.rb', 'db/migrate/fluxx_grant_create_sub_program.rb'
    handle_migration 'create_sub_initiative.rb', 'db/migrate/fluxx_grant_create_sub_initiative.rb'
    handle_migration 'add_sub_initiative_program_to_request_funding_source.rb', 'db/migrate/fluxx_grant_add_sub_initiative_program_to_request_funding_source.rb'
    handle_migration 'add_new_fields_to_funding_source.rb', 'db/migrate/fluxx_grant_add_new_fields_to_funding_source.rb'
    handle_migration 'switch_around_program_initiative_etc.rb', 'db/migrate/fluxx_grant_switch_around_program_initiative_etc.rb'
    handle_migration 'create_funding_source_allocation.rb', 'db/migrate/fluxx_grant_create_funding_source_allocation.rb'
    handle_migration 'switch_request_funding_source_authorities_to_allocation.rb', 'db/migrate/fluxx_grant_switch_request_funding_source_authorities_to_allocation.rb'
    handle_migration 'populate_funding_source_allocations.rb', 'db/migrate/fluxx_grant_populate_funding_source_allocations.rb'
    handle_migration 'add_program_geo_zone_meg.rb', 'db/migrate/fluxx_grant_add_program_geo_zone_meg.rb'
    handle_migration 'create_request_program.rb', 'db/migrate/fluxx_grant_create_request_program.rb'
    handle_migration 'add_retired_to_program_etc.rb', 'db/migrate/fluxx_grant_add_retired_to_program_etc.rb'
    handle_migration 'add_spending_year_to_funding_source_allocation.rb', 'db/migrate/fluxx_grant_add_spending_year_to_funding_source_allocation.rb'
    handle_migration 'limit_allocation_program_designation_to_one_field.rb', 'db/migrate/fluxx_grant_limit_allocation_program_designation_to_one_field.rb'
    handle_migration 'create_request_transaction_funding_source.rb', 'db/migrate/fluxx_grant_create_request_transaction_funding_source.rb'
    handle_migration 'add_payee_to_request_transaction.rb', 'db/migrate/fluxx_grant_add_payee_to_request_transaction.rb'
    handle_migration 'add_bank_account_to_transaction.rb', 'db/migrate/fluxx_grant_add_bank_account_to_transaction.rb'
    handle_migration 'make_eval_metrics_fields_text.rb', 'db/migrate/fluxx_grant_make_eval_metrics_fields_text.rb'
    handle_migration 'add_c3_field_to_organization.rb', 'db/migrate/fluxx_grant_add_c3_field_to_organization.rb'
  end
  
  private
  def handle_migration name, filename
    begin
      migration_template name, filename
      sleep 1
    rescue Exception => e
      p e.to_s
    end
  end
end
