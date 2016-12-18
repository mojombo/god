require File.dirname(__FILE__) + '/helper'

class TestConditionsUptime < Test::Unit::TestCase
  # valid?

  def test_valid_should_return_false_if_no_above_given
    c = Conditions::Uptime.new
    c.stubs(:watch).returns(stub(:pid_file => '', :name => 'foo'))

    assert_equal false, c.valid?
  end

  # test

  def test_test_should_return_true_if_above_limit
    c = Conditions::Uptime.new
    c.stubs(:watch).returns(stub(:pid => 99999999, :name => 'foo'))

    c.above = 9
    System::Process.any_instance.expects(:uptime_seconds).returns(10)

    assert_equal true, c.test
  end

  def test_test_should_return_false_if_below_limit
    c = Conditions::Uptime.new
    c.stubs(:watch).returns(stub(:pid => 99999999, :name => 'foo'))

    c.above = 11
    System::Process.any_instance.expects(:uptime_seconds).returns(10)

    assert_equal false, c.test
  end
end
