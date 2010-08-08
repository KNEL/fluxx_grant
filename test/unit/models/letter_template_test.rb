require 'test_helper'

class LetterTemplateTest < ActiveSupport::TestCase
  def setup
    @letter_template = LetterTemplate.make
  end
  
  test "test creating letter template" do
    assert @letter_template.id
  end
end