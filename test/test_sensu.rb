require File.dirname(__FILE__) + '/helper'

class TestSensu < Minitest::Test
  def test_sensu_notify
    sensu = God::Contacts::Sensu.new
    sensu.check_name = "TestSensuContact"

    UDPSocket.any_instance.expects(:send)
    sensu.notify("Test", Time.now, "Test", "Test", "")
  end
end
