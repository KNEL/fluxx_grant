class User < ActiveRecord::Base
  include FluxxUser
  include FluxxGrantUser
end
