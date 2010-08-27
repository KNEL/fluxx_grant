require 'fluxx_engine'

namespace :fluxx_grant do
  task :add_all_program_roles => :environment do
    user_id = ENV['user_id']
    user = User.find user_id if user_id
    if user
      Program.all.each do |program|
        (Program.request_roles + Program.grant_roles + Program.finance_roles).each do |role|
          user.has_role! role, program
        end
      end
    else
      p "Please add an environment variable user_id"
    end
  end
end