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
