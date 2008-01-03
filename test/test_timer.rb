require File.dirname(__FILE__) + '/helper'

class TestTimer < Test::Unit::TestCase
  def setup
    Timer.reset
    @t = Timer.get
  end
  
  def test_new_timer_should_have_no_events
    assert_equal 0, @t.events.size
  end
  
  def test_schedule_should_queue_event
    Time.stubs(:now).returns(0)
    
    w = Watch.new
    @t.schedule(stub(:interval => 20, :watch => w))
    
    assert_equal 1, @t.events.size
  end
  
  def test_timer_should_remove_expired_events
    @t.schedule(stub(:interval => -1, :watch => Watch.new))
    sleep(0.3)
    assert_equal 0, @t.events.size
  end
  
  def test_timer_should_remove_only_expired_events
    w = Watch.new
    @t.schedule(stub(:interval => -1, :watch => w))
    @t.schedule(stub(:interval => 1000, :watch => w))
    sleep(0.3)
    assert_equal 1, @t.events.size
  end
  
  def test_timer_should_sort_timer_events
    w = Watch.new
    @t.schedule(stub(:interval => 1000, :watch => w))
    @t.schedule(stub(:interval => 800, :watch => w))
    @t.schedule(stub(:interval => 900, :watch => w))
    @t.schedule(stub(:interval => 100, :watch => w))
    sleep(0.3)
    assert_equal [100, 800, 900, 1000], @t.events.map { |x| x.condition.interval }
  end
  
  def test_unschedule_should_remove_conditions
    w = Watch.new
    a = stub(:watch => w)
    b = stub(:watch => w)
    @t.schedule(a, 100)
    @t.schedule(b, 200)
    assert_equal 2, @t.events.size
    @t.unschedule(a)
    assert_equal 1, @t.events.size
  end
  
  def test_time_should_recover_from_exceptions
    w = Watch.new
    @t.expects(:trigger).raises(Exception.new)
    no_stdout do
      @t.schedule(stub(:interval => -1, :watch => w))
      sleep(0.3)
      @t.schedule(stub(:interval => 0, :watch => w))
    end
  end
  
  # join
  
  def test_join_should_join
    Thread.any_instance.expects(:join)
    @t.join
  end
end
