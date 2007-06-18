require File.dirname(__FILE__) + '/helper'

class TestReporter < Test::Unit::TestCase

  def test_should_create_a_drb_object
    DRb.expects(:start_service)
    DRbObject.expects(:new).with(nil, "druby://host:port").returns(stub(:anything => true))

    Reporter.new('host', 'port').anything
  end

  def test_should_forward_unknown_methods_to_drb_object
    Reporter.any_instance.expects(:service).returns(mock(:something_fake => true))
    
    reporter = Reporter.new('host', 'port')
    reporter.something_fake
  end
end
