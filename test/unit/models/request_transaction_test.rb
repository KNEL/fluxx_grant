require 'test_helper'

class RequestTransactionTest < ActiveSupport::TestCase
  def setup
    @request_transaction = RequestTransaction.make
  end
  
  test "test creating request transaction" do
    assert @request_transaction.id
  end
  
  test "create a req transaction and check initial state transition" do
    assert_equal 'new', @request_transaction.state
  end
  
  test "take a report and mark_paid" do
    @request_transaction.mark_paid
    assert_equal 'paid', @request_transaction.state
  end
  
  test "take a report and mark paid from due" do
    @request_transaction.state = 'due'
    @request_transaction.save
    @request_transaction.mark_paid
    assert_equal 'paid', @request_transaction.state
  end
  
end