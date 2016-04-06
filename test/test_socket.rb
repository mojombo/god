require File.dirname(__FILE__) + '/helper'

class TestSocket < Minitest::Test
  def setup
    silence_warnings do
      Object.const_set(:DRb, stub_everything)
    end
  end

  def test_should_start_a_drb_server
    DRb.expects(:start_service)
    God::Socket.new
  end

  def test_should_use_supplied_port_and_host
    DRb.expects(:start_service).with { |uri, object| uri == "drbunix://#{God::Socket.socket_file(9999)}" && object.is_a?(God::Socket) }
    server = God::Socket.new(9999)
  end

  def test_should_forward_foreign_method_calls_to_god
    server = nil
    server = God::Socket.new
    God.expects(:send).with(:something_random)
    server.something_random
  end

  # ping

  def test_ping_should_return_true
    server = nil
    server = God::Socket.new
    assert server.ping
  end

  def test_should_use_socket_dir_param
    God.socket_dir = File.absolute_path(".")
    socket_file = God::Socket.socket_file(9999)
    assert_equal "#{File.absolute_path(".")}/god.9999.sock", socket_file
  end
end
