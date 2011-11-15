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

  # socket method
  def test_socket_should_return_127_0_0_1_for_default_addr
    c = Conditions::SocketResponding.new
    c.socket = 'tcp:443'
    assert_equal c.addr, '127.0.0.1'
  end

  def test_socket_should_set_properties_for_tcp
    c = Conditions::SocketResponding.new
    c.socket = 'tcp:127.0.0.1:443'
    assert_equal c.family, 'tcp'
    assert_equal c.addr, '127.0.0.1'
    assert_equal c.port, 443
    # path should not be set for tcp sockets
    assert_equal c.path, nil
  end

  def test_socket_should_set_properties_for_unix
    c = Conditions::SocketResponding.new
    c.socket = 'unix:/tmp/process.sock'
    assert_equal c.family, 'unix'
    assert_equal c.path, '/tmp/process.sock'
    # path should not be set for unix domain sockets
    assert_equal c.port, 0
  end

  # test

  def test_test_tcp_should_return_false_if_socket_is_listening
    c = Conditions::SocketResponding.new
    c.prepare

    TCPSocket.expects(:new).returns(0)
    assert_equal false, c.test
  end

  def test_test_tcp_should_return_true_if_no_socket_is_listening
    c = Conditions::SocketResponding.new
    c.prepare

    TCPSocket.expects(:new).returns(nil)
    assert_equal true, c.test
  end

  def test_test_unix_should_return_false_if_socket_is_listening
    c = Conditions::SocketResponding.new
    c.socket = 'unix:/some/path'

    c.prepare
    UNIXSocket.expects(:new).returns(0)
    assert_equal false, c.test
  end

  def test_test_unix_should_return_true_if_no_socket_is_listening

    c = Conditions::SocketResponding.new
    c.socket = 'unix:/some/path'
    c.prepare

    UNIXSocket.expects(:new).returns(nil)
    assert_equal true, c.test
  end

  def test_test_unix_should_return_true_if_socket_is_listening_2_times

    c = Conditions::SocketResponding.new
    c.socket = 'unix:/some/path'
    c.times = [2, 2]
    c.prepare

    UNIXSocket.expects(:new).returns(nil).times(2)
    assert_equal false, c.test
    assert_equal true, c.test
  end
end
