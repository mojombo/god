require File.dirname(__FILE__) + '/helper'

class TestGod < Test::Unit::TestCase
  def test_should_create_new_meddle
    Meddle.expects(:new).with(:port => 1).returns(mock(:monitor => true, :timer => stub(:join => nil)))
    
    God.meddle(:port => 1) {}
  end

  def test_should_start_monitoring
    Meddle.any_instance.expects(:monitor)
    Meddle.any_instance.expects(:timer).returns(stub(:join => nil))
    God.meddle {}
  end
end
