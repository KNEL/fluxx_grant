require 'machinist/active_record'
require 'sham'
require 'faker'

ATTRIBUTES = {}

def bp_attrs
  ATTRIBUTES
end

# For faker formats see http://faker.rubyforge.org/rdoc/

Sham.word { Faker::Lorem.words(2).join '' }
Sham.words { Faker::Lorem.words(3).join ' ' }
Sham.sentence { Faker::Lorem.sentence }
Sham.company_name { Faker::Company.name }
Sham.first_name { Faker::Name.first_name }
Sham.last_name { Faker::Name.last_name }
Sham.login { Faker::Internet.user_name }
Sham.email { Faker::Internet.email }
Sham.url { "http://#{Faker::Internet.domain_name}/#{Faker::Lorem.words(1).first}"  }


# For machinist docs see: http://github.com/technoweenie/machinist
Program.blueprint do
  name Sham.words
end

Initiative.blueprint do
  name Sham.words
end

FundingSource.blueprint do
  name Sham.words
end

MultiElementGroup.blueprint do
end

MultiElementValue.blueprint do
end

User.blueprint do
  first_name Sham.first_name
  last_name Sham.last_name
  login(Sham.login + 'abcdef')
  email Sham.email
  created_at 5.days.ago.to_s(:db)
  state 'active'
end


def rand_nums
  "#{(99999999/rand).floor}#{Time.now.to_i}"
end

def generate_word
  "#{Sham.word}_#{rand_nums}"
end


RoleUser.blueprint do
end

Favorite.blueprint do
end

GrantRequest.blueprint do
  project_summary do
    Sham.sentence
  end
  base_request_id nil
  amount_requested 45000
  amount_recommended 45001
  duration_in_months 12
  program
  program_organization
end

FipRequest.blueprint do
  fip_title Sham.sentence
  fip_type do
    bp_attrs[:fip_type_contract]
  end
  fip_projected_end_at (-10).days.ago.to_s(:db)
  project_summary do
    Sham.sentence
  end
  amount_requested 45000
  amount_recommended 45001
  duration_in_months 12
  program
end

Organization.blueprint do
  name Sham.company_name
  city Sham.words
  street_address Sham.words
  street_address2 Sham.words
  url Sham.url
  tax_class do
    bp_attrs[:non_er_tax_status]
  end
end

UserOrganization.blueprint do
  title Sham.words
end

RequestReport.blueprint do
  request {GrantRequest.make}
  report_type RequestReport.interim_budget_type_name
end

RequestFundingSource.blueprint do
  funding_source {FundingSource.make}
  request {GrantRequest.make}
end

RequestEvaluationMetric.blueprint do
  request {GrantRequest.make}
  description Sham.words
  comment Sham.words
  achieved false
end

RequestTransaction.blueprint do
  request {GrantRequest.make}
end

LetterTemplate.blueprint do
  letter_type Sham.word
  category Sham.word
  description Sham.word
  letter Sham.sentence
end

RequestLetter.blueprint do
  request {GrantRequest.make}
  letter do
    bp_attrs[:ga_letter_template].letter
  end
  letter_template_id do
    bp_attrs[:ga_letter_template].id
  end
end

Note.blueprint do
  note Sham.sentence
  notable_type 'User'
  notable_id User.make.id
end

Group.blueprint do
  name Sham.word
end

GroupMember.blueprint do
end

RequestGeoState.blueprint do
end

RequestOrganization.blueprint do
  request {GrantRequest.make}
  organization
end

RequestUser.blueprint do
  request {GrantRequest.make}
  user
end

Project.blueprint do
  title Sham.sentence
  description Sham.sentence
end

ProjectList.blueprint do
  title Sham.sentence
  list_order 1
end

ProjectUser.blueprint do
end

ProjectOrganization.blueprint do
end

ProjectRequest.blueprint do
end

ProjectListItem.blueprint do
  name Sham.word
  list_item_text Sham.sentence
  due_at Time.now
  item_order 1
end

WikiDocument.blueprint do
  wiki_order 1
  title Sham.word
  note Sham.sentence
end

def setup_letter_templates
  unless bp_attrs[:award_letter_template]
    LetterTemplate.delete_all
    bp_attrs[:award_letter_template] = LetterTemplate.make :letter_type => 'al_public_charity', :letter => Sham.sentence, :description => 'Award Letter Public Charity', :category => 'Award', :filename => 'al_public_charity'
    bp_attrs[:ga_letter_template] = LetterTemplate.make :letter_type => 'ga_public_charity', :letter => Sham.sentence, :description => 'Grant Agreement Public Charity', :category => 'Grant Agreement', :filename => 'ga_public_charity'
  end
end

def setup_org_tax_classes
  unless bp_attrs[:executed_setup_org_tax_classes]
    MultiElementValue.delete_all
    bp_attrs[:executed_setup_org_tax_classes] = true
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => '509a1'
    bp_attrs[:non_er_tax_status] = MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => '509a2'
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => '509a3'
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => 'Private Foundation'
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => '501c4'
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => '501c6'
    MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => 'non-US'
    bp_attrs[:er_tax_status] = MultiElementValue.make :multi_element_group_id => bp_attrs[:tax_class_group].id, :value => 'Non-Exempt'
    Organization.add_multi_elements
  end
end

def setup_fip_types
  bp_attrs[:fip_type_contract] = MultiElementValue.make :multi_element_group_id => bp_attrs[:fip_type_group].id, :value => 'Contract'
end

def setup_multi_element_groups
  unless bp_attrs[:executed_setup_multi_element_groups]
    bp_attrs[:executed_setup_multi_element_groups] = true
    MultiElementValue.delete_all
    MultiElementGroup.delete_all
    bp_attrs[:test_program] = Program.make
    
    bp_attrs[:tax_class_group] = MultiElementGroup.make :name => 'tax_classes', :description => 'TaxClass', :target_class_name => 'Organization'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'expenditure_types', :description => 'ExpenditureType'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'initiative_types', :description => 'InitiativeType'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'grant_types', :description => 'RequestGrantType'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'constituents', :description => 'Constituents'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'usa_means', :description => 'MeansUsa'
    MultiElementGroup.make :target_class_name => 'Request', :name => 'china_means', :description => 'MeansChina'
    MultiElementGroup.make :target_class_name => 'RequestFundingSource', :name => 'authorities', :description => 'BoardAuthority'
    MultiElementGroup.make :target_class_name => 'User', :name => 'user_salutations', :description => 'UserSalutation'
    bp_attrs[:fip_type_group] = MultiElementGroup.make :target_class_name => 'Request', :name => 'fip_types', :description => 'Fip Types'
    Request.add_multi_elements
    RequestFundingSource.add_multi_elements
    User.add_multi_elements
  end
end