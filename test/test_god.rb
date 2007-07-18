require File.dirname(__FILE__) + '/helper'

class TestGod < Test::Unit::TestCase
  def test_should_create_new_meddle
    Meddle.expects(:new).with(:port => 1).returns(mock(:monitor => true))
    Timer.expects(:get).returns(stub(:join => nil)).times(2)
    
    God.meddle(:port => 1) {}
  end

  def test_should_start_monitoring
    Meddle.any_instance.expects(:monitor)
    Timer.expects(:get).returns(stub(:join => nil)).times(2)
    God.meddle {}
  end
end
