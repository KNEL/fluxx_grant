# This file is auto-generated from the current state of the database. Instead 
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your 
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100806151108) do

  create_table "client_stores", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "name"
    t.datetime "deleted_at"
    t.text     "data"
  end

  add_index "client_stores", ["user_id"], :name => "index_client_stores_on_user_id"

  create_table "favorites", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",        :limit => 12
    t.string   "favorable_type",               :null => false
    t.integer  "favorable_id",   :limit => 12, :null => false
  end

  create_table "funding_sources", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.string   "name"
    t.integer  "amount"
  end

  create_table "geo_cities", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",           :limit => 150, :null => false
    t.integer  "geo_state_id",   :limit => 12
    t.integer  "geo_country_id", :limit => 12
    t.string   "postalCode",     :limit => 150
    t.string   "latitude",       :limit => 150
    t.string   "longitude",      :limit => 150
    t.string   "metro_code",     :limit => 150
    t.string   "area_code",      :limit => 150
    t.integer  "original_id",    :limit => 12,  :null => false
  end

  add_index "geo_cities", ["name"], :name => "geo_cities_name_index"

  create_table "geo_countries", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                 :limit => 90, :null => false
    t.string   "fips104",              :limit => 90
    t.string   "iso2",                 :limit => 90
    t.string   "iso3",                 :limit => 90
    t.string   "ison",                 :limit => 90
    t.string   "internet",             :limit => 90
    t.string   "capital",              :limit => 90
    t.string   "map_reference",        :limit => 90
    t.string   "nationality_singular", :limit => 90
    t.string   "nationality_plural",   :limit => 90
    t.string   "currency",             :limit => 90
    t.string   "currency_code",        :limit => 90
    t.string   "population",           :limit => 90
    t.string   "title",                :limit => 90
    t.text     "comment"
    t.integer  "original_id",          :limit => 12, :null => false
  end

  add_index "geo_countries", ["iso2"], :name => "country_iso2_index"
  add_index "geo_countries", ["name"], :name => "country_name_index"

  create_table "geo_states", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",           :limit => 90, :null => false
    t.string   "fips_10_4",      :limit => 90, :null => false
    t.string   "abbreviation",   :limit => 25
    t.integer  "geo_country_id", :limit => 12, :null => false
  end

  add_index "geo_states", ["abbreviation"], :name => "geo_states_abbrv_index"
  add_index "geo_states", ["name"], :name => "geo_states_name_index"

  create_table "group_members", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.integer  "group_id"
    t.integer  "groupable_id"
    t.string   "groupable_type"
  end

  add_index "group_members", ["group_id"], :name => "index_group_members_on_group_id"
  add_index "group_members", ["groupable_id", "groupable_type"], :name => "index_group_members_on_groupable_id_and_groupable_type"

  create_table "groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "name"
    t.boolean  "deprecated",    :default => false
  end

  add_index "groups", ["name"], :name => "index_groups_on_name", :unique => true

  create_table "initiatives", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.string   "name"
    t.string   "description"
    t.integer  "program_id"
  end

  add_index "initiatives", ["program_id"], :name => "index_initiatives_on_program_id"

  create_table "letter_templates", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.string   "letter_type"
    t.string   "filename"
    t.string   "description"
    t.string   "category"
    t.text     "letter"
    t.datetime "deleted_at"
    t.boolean  "delta",                       :default => true, :null => false
  end

  create_table "model_documents", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",         :limit => 12
    t.integer  "updated_by_id",         :limit => 12
    t.string   "document_file_name"
    t.string   "document_content_type"
    t.integer  "document_file_size"
    t.datetime "document_updated_at"
    t.string   "documentable_type",                   :null => false
    t.integer  "documentable_id",       :limit => 12, :null => false
    t.datetime "locked_until"
    t.integer  "locked_by_id"
  end

  create_table "multi_element_choices", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "target_id",              :limit => 12, :null => false
    t.integer  "multi_element_value_id", :limit => 12, :null => false
  end

  add_index "multi_element_choices", ["target_id", "multi_element_value_id"], :name => "multi_element_choices_index_cl_attr_val", :unique => true

  create_table "multi_element_groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "target_class_name", :null => false
    t.string   "name"
    t.string   "description"
  end

  create_table "multi_element_values", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description"
    t.string   "value"
    t.integer  "multi_element_group_id", :limit => 12
  end

  add_index "multi_element_values", ["multi_element_group_id"], :name => "index_multi_element_values_on_multi_element_group_id"

  create_table "notes", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.text     "note",                                          :null => false
    t.string   "notable_type",                                  :null => false
    t.integer  "notable_id",    :limit => 12,                   :null => false
    t.boolean  "delta",                       :default => true
    t.datetime "deleted_at"
    t.datetime "locked_until"
    t.integer  "locked_by_id"
  end

  create_table "organizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",   :limit => 12
    t.integer  "updated_by_id",   :limit => 12
    t.string   "name",            :limit => 1000,                    :null => false
    t.string   "street_address"
    t.string   "street_address2"
    t.string   "city",            :limit => 100
    t.integer  "geo_state_id",    :limit => 12
    t.integer  "geo_country_id",  :limit => 12
    t.string   "postal_code",     :limit => 100
    t.string   "phone",           :limit => 100
    t.string   "other_contact",   :limit => 100
    t.string   "fax",             :limit => 100
    t.string   "email",           :limit => 100
    t.string   "url",             :limit => 2048
    t.string   "blog_url",        :limit => 2048
    t.string   "twitter_url",     :limit => 2048
    t.string   "acronym",         :limit => 100
    t.string   "state",                           :default => "new"
    t.boolean  "delta",                           :default => true
    t.datetime "deleted_at"
    t.integer  "parent_org_id",   :limit => 12
    t.datetime "locked_until"
    t.integer  "locked_by_id"
    t.integer  "tax_class_id"
  end

  add_index "organizations", ["name"], :name => "index_organizations_on_name"
  add_index "organizations", ["parent_org_id"], :name => "index_organizations_on_parent_org_id"

  create_table "programs", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",     :limit => 12
    t.integer  "updated_by_id",     :limit => 12
    t.string   "name"
    t.string   "description"
    t.integer  "parent_program_id", :limit => 12
    t.boolean  "rollup"
  end

  add_index "programs", ["parent_program_id"], :name => "index_programs_on_parent_program_id"

  create_table "realtime_updates", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "action",                         :null => false
    t.integer  "user_id",          :limit => 12
    t.integer  "model_id",         :limit => 12, :null => false
    t.string   "type_name",                      :null => false
    t.string   "model_class",                    :null => false
    t.text     "delta_attributes",               :null => false
  end

  create_table "request_funding_sources", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",      :limit => 12
    t.integer  "updated_by_id",      :limit => 12
    t.integer  "request_id",         :limit => 12
    t.integer  "funding_source_id",  :limit => 12
    t.integer  "program_id",         :limit => 12
    t.integer  "initiative_id",      :limit => 12
    t.string   "document_file_name"
    t.integer  "funding_amount",     :limit => 12
    t.integer  "locked_by_id",       :limit => 12
    t.datetime "locked_until"
  end

  add_index "request_funding_sources", ["funding_source_id"], :name => "index_request_funding_sources_on_funding_source_id"
  add_index "request_funding_sources", ["initiative_id"], :name => "index_request_funding_sources_on_initiative_id"
  add_index "request_funding_sources", ["program_id"], :name => "index_request_funding_sources_on_program_id"
  add_index "request_funding_sources", ["request_id"], :name => "index_request_funding_sources_on_request_id"

  create_table "request_geo_states", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.integer  "request_id",    :limit => 12
    t.integer  "geo_state_id",  :limit => 12
  end

  add_index "request_geo_states", ["geo_state_id"], :name => "index_request_geo_states_on_geo_state_id"
  add_index "request_geo_states", ["request_id"], :name => "index_request_geo_states_on_request_id"

  create_table "request_letters", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",      :limit => 12
    t.integer  "updated_by_id",      :limit => 12
    t.integer  "request_id",         :limit => 12
    t.integer  "letter_template_id", :limit => 12
    t.text     "letter"
    t.integer  "locked_by_id",       :limit => 12
    t.datetime "locked_until"
    t.datetime "deleted_at"
    t.boolean  "delta",                            :default => true, :null => false
  end

  add_index "request_letters", ["letter_template_id"], :name => "index_request_letters_on_letter_template_id"
  add_index "request_letters", ["request_id"], :name => "index_request_letters_on_request_id"

  create_table "request_organizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",   :limit => 12
    t.integer  "updated_by_id",   :limit => 12
    t.integer  "request_id",      :limit => 12
    t.integer  "organization_id", :limit => 12
    t.string   "description"
  end

  add_index "request_organizations", ["request_id", "organization_id"], :name => "index_request_organizations_on_request_id_and_organization_id", :unique => true

  create_table "request_reports", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",       :limit => 12
    t.integer  "updated_by_id",       :limit => 12
    t.integer  "request_id",          :limit => 12
    t.integer  "approved_by_user_id", :limit => 12
    t.string   "state"
    t.string   "report_type",                       :default => "RequestReport", :null => false
    t.integer  "evaluation_rating"
    t.text     "report"
    t.datetime "due_at"
    t.datetime "approved_at"
    t.integer  "locked_by_id",        :limit => 12
    t.datetime "locked_until"
    t.datetime "deleted_at"
    t.boolean  "delta",                             :default => true,            :null => false
  end

  add_index "request_reports", ["request_id"], :name => "index_request_reports_on_request_id"

  create_table "request_transactions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",               :limit => 12
    t.integer  "updated_by_id",               :limit => 12
    t.integer  "request_id",                  :limit => 12
    t.integer  "amount_paid",                 :limit => 12
    t.integer  "amount_due",                  :limit => 12
    t.datetime "due_at"
    t.datetime "paid_at"
    t.string   "comment"
    t.string   "payment_type"
    t.string   "payment_confirmation_number"
    t.integer  "payment_recorded_by_id",      :limit => 12
    t.string   "state"
    t.integer  "locked_by_id",                :limit => 12
    t.datetime "locked_until"
    t.datetime "deleted_at"
    t.boolean  "delta",                                     :default => true, :null => false
  end

  add_index "request_transactions", ["payment_recorded_by_id"], :name => "index_request_transactions_on_payment_recorded_by_id"
  add_index "request_transactions", ["request_id"], :name => "index_request_transactions_on_request_id"

  create_table "request_users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id", :limit => 12
    t.integer  "updated_by_id", :limit => 12
    t.integer  "request_id",    :limit => 12
    t.integer  "user_id",       :limit => 12
    t.string   "description"
  end

  add_index "request_users", ["request_id"], :name => "index_request_users_on_request_id"
  add_index "request_users", ["user_id"], :name => "index_request_users_on_user_id"

  create_table "requests", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",                     :limit => 12
    t.integer  "updated_by_id",                     :limit => 12
    t.integer  "program_organization_id",           :limit => 12
    t.integer  "fiscal_organization_id",            :limit => 12
    t.integer  "program_id",                        :limit => 12
    t.integer  "initiative_id",                     :limit => 12
    t.boolean  "granted"
    t.boolean  "renewal_grant"
    t.boolean  "funding_general_operating_support"
    t.boolean  "board_authorization_required"
    t.datetime "request_received_at"
    t.datetime "grant_approved_at"
    t.datetime "grant_agreement_at"
    t.datetime "grant_begins_at"
    t.datetime "grant_closed_at"
    t.integer  "amount_requested",                  :limit => 12
    t.integer  "amount_recommended",                :limit => 12
    t.integer  "duration_in_months",                :limit => 12
    t.string   "project_summary"
    t.string   "base_request_id"
    t.string   "fip_title"
    t.string   "fip_consultant_name"
    t.datetime "fip_projected_end_at"
    t.datetime "ierf_start_at"
    t.datetime "ierf_proposed_end_at"
    t.datetime "ierf_budget_end_at"
    t.text     "ierf_goals"
    t.text     "ierf_tactics"
    t.text     "ierf_probability"
    t.text     "ierf_due_diligence_overlap"
    t.text     "ierf_due_diligence_risks"
    t.text     "ierf_due_diligence_noc4_work"
    t.text     "ierf_due_diligence_board_review"
    t.integer  "funds_expended_amount"
    t.datetime "funds_expended_at"
    t.string   "type"
    t.string   "state"
    t.integer  "locked_by_id",                      :limit => 12
    t.datetime "locked_until"
    t.datetime "deleted_at"
    t.boolean  "delta",                                           :default => true, :null => false
  end

  add_index "requests", ["fiscal_organization_id"], :name => "index_requests_on_fiscal_organization_id"
  add_index "requests", ["granted"], :name => "index_requests_on_granted"
  add_index "requests", ["initiative_id"], :name => "index_requests_on_initiative_id"
  add_index "requests", ["program_id"], :name => "index_requests_on_program_id"
  add_index "requests", ["program_organization_id"], :name => "index_requests_on_program_organization_id"

  create_table "user_organizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",   :limit => 12
    t.integer  "updated_by_id",   :limit => 12
    t.integer  "user_id",         :limit => 12
    t.integer  "organization_id", :limit => 12
    t.string   "title",           :limit => 400
    t.string   "department",      :limit => 400
    t.string   "email",           :limit => 400
    t.string   "phone",           :limit => 400
    t.datetime "deleted_at"
    t.datetime "locked_until"
    t.integer  "locked_by_id"
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id",                :limit => 12
    t.integer  "updated_by_id",                :limit => 12
    t.text     "roles_text"
    t.string   "login",                        :limit => 40
    t.string   "first_name",                   :limit => 400,  :default => ""
    t.string   "last_name",                    :limit => 400,  :default => ""
    t.string   "email",                        :limit => 250
    t.string   "personal_email",               :limit => 400
    t.string   "salutation",                   :limit => 400
    t.string   "prefix",                       :limit => 400
    t.string   "middle_initial",               :limit => 400
    t.string   "personal_phone",               :limit => 400
    t.string   "personal_mobile",              :limit => 400
    t.string   "personal_fax",                 :limit => 400
    t.string   "personal_street_address",      :limit => 400
    t.string   "personal_street_address2",     :limit => 400
    t.string   "personal_city",                :limit => 400
    t.integer  "personal_geo_state_id",        :limit => 12
    t.integer  "personal_geo_country_id",      :limit => 12
    t.string   "personal_postal_code",         :limit => 400
    t.string   "work_phone",                   :limit => 400
    t.string   "work_fax",                     :limit => 400
    t.string   "other_contact",                :limit => 400
    t.string   "assistant_name",               :limit => 400
    t.string   "assistant_phone",              :limit => 400
    t.string   "assistant_email",              :limit => 400
    t.string   "blog_url",                     :limit => 2048
    t.string   "twitter_url",                  :limit => 2048
    t.datetime "birth_at"
    t.string   "state",                                        :default => "passive"
    t.boolean  "delta",                                        :default => true
    t.datetime "deleted_at"
    t.string   "user_salutation",              :limit => 40
    t.integer  "primary_user_organization_id", :limit => 12
    t.datetime "last_logged_in_at"
    t.string   "time_zone",                    :limit => 40,   :default => "Pacific Time (US & Canada)"
    t.datetime "locked_until"
    t.integer  "locked_by_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "workflow_events", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "workflowable_type"
    t.integer  "workflowable_id"
    t.string   "ip_address"
    t.string   "old_state"
    t.string   "new_state"
    t.text     "comment"
  end

  add_index "workflow_events", ["workflowable_id", "workflowable_type"], :name => "index_workflow_events_on_workflowable_id_and_workflowable_type"

end
