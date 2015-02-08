require File.dirname(__FILE__) + '/helper'

class TestConditionsTime < Minitest::Test
  
  def setup
    @condition = Conditions::ProcessTime.new
    @condition.stubs(:pid).returns(123)

    @system_process = mock()
    System::Process.expects(:new).returns(@system_process)
  end

  def test_test_is_true_when_a_process_is_running_longer_than_requested
    @condition.alive_longer_than = 20
    @system_process.expects(:elapsed_time).returns(30)

    assert_equal true, @condition.test
  end

  def test_test_is_false_when_a_process_is_running_less_than_requested
    @condition.alive_longer_than = 20
    @system_process.expects(:elapsed_time).returns(10)

    assert_equal false, @condition.test
  end

end
