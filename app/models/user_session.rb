class UserSession < Authlogic::Session::Base
  def to_key
     new_record? ? nil : [ self.send(self.class.primary_key) ]
  end
  
  def save_cookie
  end
end

