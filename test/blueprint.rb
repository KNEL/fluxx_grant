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
  password 'eshansen'
  password_confirmation 'eshansen'
  login Sham.login
  email Sham.email
  created_at 5.days.ago.to_s(:db)
  activated_at 5.days.ago.to_s(:db)
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
  program Program.make
  program_organization Organization.make
end

FipRequest.blueprint do
  fip_title Sham.sentence
  fip_projected_end_at (-10).days.ago.to_s(:db)
  project_summary do
    Sham.sentence
  end
  amount_requested 45000
  amount_recommended 45001
  duration_in_months 12
  program Program.make
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
  request GrantRequest.make
  report_type RequestReport.interim_budget_type_name
end

RequestFundingSource.blueprint do
  funding_source FundingSource.make
  request GrantRequest.make
end

RequestTransaction.blueprint do
end

LetterTemplate.blueprint do
  letter_type Sham.word
  letter Sham.sentence
end

RequestLetter.blueprint do
  request GrantRequest.make
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


def setup_multi_element_groups
  unless bp_attrs[:executed_setup_multi_element_groups]
    bp_attrs[:executed_setup_multi_element_groups] = true
    MultiElementValue.delete_all
    MultiElementGroup.delete_all
  end
end