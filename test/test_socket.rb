require File.dirname(__FILE__) + '/helper'

class TestSocket < Test::Unit::TestCase
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
    DRb.expects(:start_service).with { |uri, object| uri == "drbunix:///tmp/god.9999.sock" && object.is_a?(God::Socket) }
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
end
