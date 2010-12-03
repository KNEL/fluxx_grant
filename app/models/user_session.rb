class UserSession < Authlogic::Session::Base
  def to_key
     new_record? ? nil : [ self.send(self.class.primary_key) ]
  end
  
  private
  # NOTE ESH: Copied this method straight from authlogic's lib/authlogic/session/cookies.rb
  #           to force it to send the user_credentials cookie back with EVERY request.  This is an effort to prevent the session cookie
  #           or user_credentials cookie from being dropped
  # Tries to validate the session from information in the cookie
  def persist_by_cookie
    persistence_token, record_id = cookie_credentials
    if !persistence_token.nil?
      self.record = record_id.nil? ? search_for_record("find_by_persistence_token", persistence_token) : search_for_record("find_by_#{klass.primary_key}", record_id)
      self.unauthorized_record = record if record && record.persistence_token == persistence_token
      retval = valid?
      # Force the cookie to be sent back to the browser each time so it can be regained if it gets dropped
      save_cookie if retval && self.record
      retval
    else
      false
    end
  end
end

