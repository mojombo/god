require File.dirname(__FILE__) + '/helper'

class TestConditionsSocketResponding < Test::Unit::TestCase
  # valid?

  def test_valid_should_return_false_if_no_options_set
    c = Conditions::SocketResponding.new
    c.watch = stub(:name => 'foo')
    assert_equal false, c.valid?

  end

  def test_valid_should_return_true_if_required_options_set_for_default
    c = Conditions::SocketResponding.new
    c.port = 443
    assert_equal true, c.valid?
  end

  def test_valid_should_return_true_if_required_options_set_for_tcp
    c = Conditions::SocketResponding.new
    c.family = 'tcp'
    c.port = 443
    assert_equal true, c.valid?
  end

  def test_valid_should_return_true_if_required_options_set_for_unix
    c = Conditions::SocketResponding.new
    c.path = 'some-path'
    c.family = 'unix'
    assert_equal true, c.valid?
  end

  def test_valid_should_return_true_if_family_is_tcp
    c = Conditions::SocketResponding.new
    c.port = 443
    c.family = 'tcp'
    assert_equal true, c.valid?
  end

  def test_valid_should_return_true_if_family_is_unix
    c = Conditions::SocketResponding.new
    c.path = 'some-path'
    c.family = 'unix'
    c.watch = stub(:name => 'foo')
    assert_equal true, c.valid?
  end

  # test

  def test_test_should_return_true_if_socket_is_listening
    c = Conditions::SocketResponding.new
    c.port = 3000

#    c.expects(:`).returns(0)
    assert_equal true, c.test
  end

  def test_test_should_return_false_if_no_socket_is_listening
    c = Conditions::SocketResponding.new
    c.port = 80

#    c.expects(:`).returns(-1)
    assert_equal false, c.test
  end
end
