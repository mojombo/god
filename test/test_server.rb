require File.dirname(__FILE__) + '/helper'

class TestServer < Test::Unit::TestCase
  def setup
    silence_warnings do 
      Object.const_set(:DRb, stub_everything)
    end
  end

  def test_should_start_a_drb_server
    DRb.expects(:start_service)
    Server.new
  end

  def test_should_use_supplied_port_and_host
    DRb.expects(:start_service).with { |uri, object| uri == "druby://host:port" && object.is_a?(Server) }
    server = Server.new(nil, 'host', 'port')
  end

  def test_should_forward_foreign_method_calls_to_meddle
    server = Server.new(mock(:something_random => true))
    server.something_random
  end
end
