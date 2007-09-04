require File.dirname(__FILE__) + '/helper'

class TestServer < Test::Unit::TestCase
  def setup
    silence_warnings do 
      Object.const_set(:DRb, stub_everything)
    end
  end

  def test_should_start_a_drb_server
    DRb.expects(:start_service)
    no_stdout do
      Server.new
    end
  end

  def test_should_use_supplied_port_and_host
    DRb.expects(:start_service).with { |uri, object| uri == "druby://host:port" && object.is_a?(Server) }
    no_stdout do
      server = Server.new('host', 'port')
    end
  end

  def test_should_forward_foreign_method_calls_to_god
    server = nil
    no_stdout do
      server = Server.new
    end
    God.expects(:send).with(:something_random)
    server.something_random
  end
  
  def test_should_install_deny_all_by_default
    ACL.expects(:new).with(%w{deny all})
    no_stdout do
      Server.new
    end
  end
  
  def test_should_install_pass_through_acl
    ACL.expects(:new).with(%w{deny all allow localhost allow 0.0.0.0})
    no_stdout do
      Server.new(nil, 17165, %w{localhost 0.0.0.0})
    end
  end
  
  # ping
  
  def test_ping_should_return_true
    server = nil
    no_stdout do
      server = Server.new
    end
    assert server.ping
  end
end
