# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{fluxx_grant}
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Eric Hansen"]
  s.date = %q{2010-10-20}
  s.email = %q{fluxx@acesfconsulting.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.textile"
  ]
  s.files = [
    "app/controllers/application_controller.rb",
     "app/controllers/fip_requests_controller.rb",
     "app/controllers/grant_requests_controller.rb",
     "app/controllers/granted_requests_controller.rb",
     "app/controllers/organizations_controller.rb",
     "app/controllers/programs_controller.rb",
     "app/controllers/request_evaluation_metrics_controller.rb",
     "app/controllers/request_funding_sources_controller.rb",
     "app/controllers/request_letters_controller.rb",
     "app/controllers/request_organizations_controller.rb",
     "app/controllers/request_reports_controller.rb",
     "app/controllers/request_transactions_controller.rb",
     "app/controllers/request_users_controller.rb",
     "app/controllers/users_controller.rb",
     "app/helpers/application_grant_helper.rb",
     "app/models/fip_request.rb",
     "app/models/funding_source.rb",
     "app/models/grant_request.rb",
     "app/models/initiative.rb",
     "app/models/letter_template.rb",
     "app/models/organization.rb",
     "app/models/program.rb",
     "app/models/request.rb",
     "app/models/request_evaluation_metric.rb",
     "app/models/request_funding_source.rb",
     "app/models/request_geo_state.rb",
     "app/models/request_letter.rb",
     "app/models/request_organization.rb",
     "app/models/request_report.rb",
     "app/models/request_transaction.rb",
     "app/models/request_user.rb",
     "app/models/role_user.rb",
     "app/models/user.rb",
     "app/models/user_organization.rb",
     "app/models/workflow_event.rb",
     "app/stylesheets/theme/default/funnel.sass",
     "app/stylesheets/theme/default/style.sass",
     "app/views/fip_requests/_fip_request_filter.html.haml",
     "app/views/fip_requests/_fip_request_form.html.haml",
     "app/views/grant_requests/_approve_grant_details.html.haml",
     "app/views/grant_requests/_edit_request_report.html.haml",
     "app/views/grant_requests/_edit_request_transaction.html.haml",
     "app/views/grant_requests/_fiscal_org.html.haml",
     "app/views/grant_requests/_funnel.html.haml",
     "app/views/grant_requests/_funnel_footer.html.haml",
     "app/views/grant_requests/_grant_request_filter.html.haml",
     "app/views/grant_requests/_grant_request_form.html.haml",
     "app/views/grant_requests/_grant_request_list.html.haml",
     "app/views/grant_requests/_grant_request_show.html.haml",
     "app/views/grant_requests/_program_org.html.haml",
     "app/views/grant_requests/_related_request.html.haml",
     "app/views/grant_requests/_request_became_grant.html.haml",
     "app/views/grant_requests/_request_letters.html.haml",
     "app/views/grant_requests/_view_states.html.haml",
     "app/views/granted_requests/_grant_request_list.html.haml",
     "app/views/granted_requests/_granted_request_filter.html.haml",
     "app/views/insta/_list_actions.html.haml",
     "app/views/insta/_show_action_buttons.html.haml",
     "app/views/letter_templates/al_china_er.html.erb",
     "app/views/letter_templates/al_gos.html.erb",
     "app/views/letter_templates/al_multiyear.html.erb",
     "app/views/letter_templates/al_public_charity.html.erb",
     "app/views/letter_templates/al_us_er.html.erb",
     "app/views/letter_templates/ga_china_er.html.erb",
     "app/views/letter_templates/ga_gos.html.erb",
     "app/views/letter_templates/ga_multiyear.html.erb",
     "app/views/letter_templates/ga_public_charity.html.erb",
     "app/views/letter_templates/ga_us_er.html.erb",
     "app/views/organizations/_organization_filter.html.haml",
     "app/views/organizations/_organization_form.html.haml",
     "app/views/organizations/_related_organization.html.haml",
     "app/views/programs/_program_form.html.haml",
     "app/views/programs/_program_list.html.haml",
     "app/views/programs/_program_show.html.haml",
     "app/views/request_evaluation_metrics/_list_request_evaluation_metrics.html.haml",
     "app/views/request_evaluation_metrics/_request_evaluation_metrics_form.html.haml",
     "app/views/request_evaluation_metrics/_request_evaluation_metrics_list.html.haml",
     "app/views/request_evaluation_metrics/_request_evaluation_metrics_show.html.haml",
     "app/views/request_funding_sources/_list_request_funding_sources.html.haml",
     "app/views/request_funding_sources/_request_funding_source_form.html.haml",
     "app/views/request_funding_sources/_request_funding_source_list.html.haml",
     "app/views/request_funding_sources/_request_funding_source_show.html.haml",
     "app/views/request_letters/_request_letter_form.html.haml",
     "app/views/request_letters/_request_letter_list.html.haml",
     "app/views/request_letters/_request_letter_show.html.erb",
     "app/views/request_organizations/_list_request_organizations.html.haml",
     "app/views/request_organizations/_request_organization_form.html.haml",
     "app/views/request_organizations/_request_organization_list.html.haml",
     "app/views/request_organizations/_request_organization_show.html.haml",
     "app/views/request_reports/_list_item1.html.haml",
     "app/views/request_reports/_related_documents.html.haml",
     "app/views/request_reports/_request_report_filter.html.haml",
     "app/views/request_reports/_request_report_form.html.haml",
     "app/views/request_reports/_request_report_list.html.haml",
     "app/views/request_reports/_request_report_show.html.haml",
     "app/views/request_transactions/_related_request_transactions.html.haml",
     "app/views/request_transactions/_request_transaction_filter.html.haml",
     "app/views/request_transactions/_request_transaction_form.html.haml",
     "app/views/request_transactions/_request_transaction_list.html.haml",
     "app/views/request_transactions/_request_transaction_show.html.haml",
     "app/views/request_users/_list_request_users.html.haml",
     "app/views/request_users/_request_user_form.html.haml",
     "app/views/request_users/_request_user_list.html.haml",
     "app/views/request_users/_request_user_show.html.haml",
     "app/views/role_users/_role_user_form.html.haml",
     "app/views/users/_related_users.html.haml",
     "app/views/users/_user_filter.html.haml",
     "app/views/users/_user_form_header.html.haml",
     "config/routes.rb",
     "lib/extensions/controllers/fluxx_common_requests_controller.rb",
     "lib/extensions/controllers/fluxx_fip_requests_controller.rb",
     "lib/extensions/controllers/fluxx_grant_organizations_controller.rb",
     "lib/extensions/controllers/fluxx_grant_requests_controller.rb",
     "lib/extensions/controllers/fluxx_grant_users_controller.rb",
     "lib/extensions/controllers/fluxx_granted_requests_controller.rb",
     "lib/extensions/controllers/fluxx_programs_controller.rb",
     "lib/extensions/controllers/fluxx_request_evaluation_metrics_controller.rb",
     "lib/extensions/controllers/fluxx_request_funding_sources_controller.rb",
     "lib/extensions/controllers/fluxx_request_letters_controller.rb",
     "lib/extensions/controllers/fluxx_request_organizations_controller.rb",
     "lib/extensions/controllers/fluxx_request_reports_controller.rb",
     "lib/extensions/controllers/fluxx_request_transactions_controller.rb",
     "lib/extensions/controllers/fluxx_request_users_controller.rb",
     "lib/extensions/models/fluxx_fip_request.rb",
     "lib/extensions/models/fluxx_funding_source.rb",
     "lib/extensions/models/fluxx_grant_organization.rb",
     "lib/extensions/models/fluxx_grant_request.rb",
     "lib/extensions/models/fluxx_grant_role_user.rb",
     "lib/extensions/models/fluxx_grant_user.rb",
     "lib/extensions/models/fluxx_grant_user_organization.rb",
     "lib/extensions/models/fluxx_grant_workflow_event.rb",
     "lib/extensions/models/fluxx_initiative.rb",
     "lib/extensions/models/fluxx_letter_template.rb",
     "lib/extensions/models/fluxx_program.rb",
     "lib/extensions/models/fluxx_request.rb",
     "lib/extensions/models/fluxx_request_evaluation_metric.rb",
     "lib/extensions/models/fluxx_request_funding_source.rb",
     "lib/extensions/models/fluxx_request_geo_state.rb",
     "lib/extensions/models/fluxx_request_letter.rb",
     "lib/extensions/models/fluxx_request_organization.rb",
     "lib/extensions/models/fluxx_request_report.rb",
     "lib/extensions/models/fluxx_request_transaction.rb",
     "lib/extensions/models/fluxx_request_user.rb",
     "lib/fluxx_grant.rb",
     "lib/fluxx_grant/engine.rb",
     "lib/generators/fluxx_grant_migration/fluxx_grant_migration_generator.rb",
     "lib/generators/fluxx_grant_migration/templates/add_grant_fields_to_organization.rb",
     "lib/generators/fluxx_grant_migration/templates/create_funding_sources.rb",
     "lib/generators/fluxx_grant_migration/templates/create_initiatives.rb",
     "lib/generators/fluxx_grant_migration/templates/create_letter_templates.rb",
     "lib/generators/fluxx_grant_migration/templates/create_programs.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_evaluation_metrics.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_funding_sources.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_geo_states.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_letters.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_organizations.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_reports.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_transactions.rb",
     "lib/generators/fluxx_grant_migration/templates/create_request_users.rb",
     "lib/generators/fluxx_grant_migration/templates/create_requests.rb",
     "lib/generators/fluxx_grant_public/fluxx_grant_public_generator.rb",
     "lib/generators/fluxx_grant_seed/fluxx_grant_seed_generator.rb",
     "lib/tasks.rb",
     "public/images/theme/default/funnel/arrow-tip.png",
     "public/images/theme/default/funnel/arrow.png",
     "public/javascripts/README.txt",
     "public/stylesheets/README.txt"
  ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Fluxx Grant Core}
  s.test_files = [
    "test/blueprint.rb",
     "test/dummy/app/controllers/application_controller.rb",
     "test/dummy/app/helpers/application_helper.rb",
     "test/dummy/config/application.rb",
     "test/dummy/config/boot.rb",
     "test/dummy/config/environment.rb",
     "test/dummy/config/environments/development.rb",
     "test/dummy/config/environments/production.rb",
     "test/dummy/config/environments/test.rb",
     "test/dummy/config/initializers/backtrace_silencers.rb",
     "test/dummy/config/initializers/inflections.rb",
     "test/dummy/config/initializers/mime_types.rb",
     "test/dummy/config/initializers/secret_token.rb",
     "test/dummy/config/initializers/session_store.rb",
     "test/dummy/config/routes.rb",
     "test/dummy/db/migrate/20100803151248_fluxx_engine_create_realtime_updates_table.rb",
     "test/dummy/db/migrate/20100803151249_fluxx_engine_create_multi_element_groups.rb",
     "test/dummy/db/migrate/20100803151250_fluxx_engine_create_multi_element_values.rb",
     "test/dummy/db/migrate/20100803151251_fluxx_engine_create_multi_element_choices.rb",
     "test/dummy/db/migrate/20100803151252_fluxx_engine_create_client_stores.rb",
     "test/dummy/db/migrate/20100803151554_fluxx_crm_create_geo_countries.rb",
     "test/dummy/db/migrate/20100803151555_fluxx_crm_create_geo_states.rb",
     "test/dummy/db/migrate/20100803151556_fluxx_crm_create_geo_cities.rb",
     "test/dummy/db/migrate/20100803151557_fluxx_crm_create_model_documents.rb",
     "test/dummy/db/migrate/20100803151558_fluxx_crm_create_organizations.rb",
     "test/dummy/db/migrate/20100803151559_fluxx_crm_create_user_organizations.rb",
     "test/dummy/db/migrate/20100803151600_fluxx_crm_create_users.rb",
     "test/dummy/db/migrate/20100803151601_fluxx_crm_create_notes.rb",
     "test/dummy/db/migrate/20100803151602_fluxx_crm_create_favorites.rb",
     "test/dummy/db/migrate/20100803151603_fluxx_crm_create_groups.rb",
     "test/dummy/db/migrate/20100803151604_fluxx_crm_create_group_members.rb",
     "test/dummy/db/migrate/20100803151605_fluxx_crm_create_workflow_events.rb",
     "test/dummy/db/migrate/20100803152034_fluxx_grant_create_programs.rb",
     "test/dummy/db/migrate/20100803152035_fluxx_grant_create_funding_sources.rb",
     "test/dummy/db/migrate/20100803152036_fluxx_grant_create_initiatives.rb",
     "test/dummy/db/migrate/20100803152037_fluxx_grant_create_letter_templates.rb",
     "test/dummy/db/migrate/20100803152038_fluxx_grant_create_requests.rb",
     "test/dummy/db/migrate/20100803152039_fluxx_grant_create_request_letters.rb",
     "test/dummy/db/migrate/20100803152040_fluxx_grant_create_request_organizations.rb",
     "test/dummy/db/migrate/20100803152041_fluxx_grant_create_request_reports.rb",
     "test/dummy/db/migrate/20100803152042_fluxx_grant_create_request_transactions.rb",
     "test/dummy/db/migrate/20100803152043_fluxx_grant_create_request_funding_sources.rb",
     "test/dummy/db/migrate/20100803152044_fluxx_grant_create_request_users.rb",
     "test/dummy/db/migrate/20100803152045_fluxx_grant_create_request_geo_states.rb",
     "test/dummy/db/migrate/20100806151108_fluxx_grant_add_grant_fields_to_organization.rb",
     "test/dummy/db/migrate/20100809090857_acts_as_audited_migration.rb",
     "test/dummy/db/migrate/20100819101944_fluxx_crm_create_role_users.rb",
     "test/dummy/db/migrate/20101018233010_fluxx_crm_create_geo_regions.rb",
     "test/dummy/db/migrate/20101018233011_fluxx_crm_create_documents.rb",
     "test/dummy/db/migrate/20101018233051_fluxx_grant_create_request_evaluation_metrics.rb",
     "test/dummy/db/schema.rb",
     "test/dummy/db/seeds.rb",
     "test/fluxx_grant_test.rb",
     "test/functional/fip_requests_controller_test.rb",
     "test/functional/grant_requests_controller_test.rb",
     "test/functional/granted_requests_controller_test.rb",
     "test/functional/request_evaluation_metrics_controller_test.rb",
     "test/functional/request_funding_sources_controller_test.rb",
     "test/functional/request_letters_controller_test.rb",
     "test/functional/request_organizations_controller_test.rb",
     "test/functional/request_reports_controller_test.rb",
     "test/functional/request_transactions_controller_test.rb",
     "test/functional/request_users_controller_test.rb",
     "test/functional/users_controller_test.rb",
     "test/integration/navigation_test.rb",
     "test/support/integration_case.rb",
     "test/test_helper.rb",
     "test/unit/models/funding_source_test.rb",
     "test/unit/models/grant_request_test.rb",
     "test/unit/models/initiative_test.rb",
     "test/unit/models/letter_template_test.rb",
     "test/unit/models/organization_test.rb",
     "test/unit/models/program_test.rb",
     "test/unit/models/request_funding_source_test.rb",
     "test/unit/models/request_geo_state_test.rb",
     "test/unit/models/request_letter_test.rb",
     "test/unit/models/request_organization_test.rb",
     "test/unit/models/request_report_test.rb",
     "test/unit/models/request_transaction_test.rb",
     "test/unit/models/request_user_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

