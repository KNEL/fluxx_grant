require 'test_helper'

class RequestTransactionTest < ActiveSupport::TestCase
  def setup
    @request_transaction = RequestTransaction.make
  end
  
  test "test creating request transaction" do
    assert @request_transaction.id
  end
end