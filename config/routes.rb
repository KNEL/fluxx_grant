Rails.application.routes.draw do
  resources :request_transaction_funding_sources

  resources :modal_reports

  resources :request_programs

  resources :funding_sources

  resources :admin_cards

  resources :funding_source_allocations

  resources :sub_initiatives

  resources :sub_programs

  resources :request_funding_sources
  resources :request_evaluation_metrics
  resources :request_transactions
  resources :grant_requests
  resources :fip_requests
  resources :request_letters
  resources :request_users
  resources :granted_requests
  resources :request_organizations
  resources :programs
  resources :initiatives
  resources :request_reports
  resources :project_requests
  resources :outside_grants

end