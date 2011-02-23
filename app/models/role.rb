class Role < ActiveRecord::Base
  include FluxxRole
  add_roleable_type 'Program', Program.name
end