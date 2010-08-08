require 'test_helper'

class RequestLetterTest < ActiveSupport::TestCase
  def setup
    @request_letter = RequestLetter.make
  end
  
  test "test creating request letter" do
    assert @request_letter.id
  end
end