require File.dirname(__FILE__) + '/helper'

class TestTimer < Test::Unit::TestCase
  def setup
    @t = Timer.new
  end
  
  def test_new_timer_should_have_no_events
    assert_equal 0, @t.events.size
  end
  
  def test_register_should_queue_event
    Time.stubs(:now).returns(0)
    
    w = Watch.new(nil)
    @t.register(w, stub(:interval => 20), nil)
    
    assert_equal 1, @t.events.size
    assert_equal w, @t.events.first.watch
  end
  
  def test_timer_should_remove_expired_events
    @t.register(nil, stub(:interval => 0), nil)
    sleep(0.3)
    assert_equal 0, @t.events.size
  end
  
  def test_timer_should_remove_only_expired_events
    @t.register(nil, stub(:interval => 0), nil)
    @t.register(nil, stub(:interval => 1000), nil)
    sleep(0.3)
    assert_equal 1, @t.events.size
  end
  
  def test_timer_should_sort_timer_events
    @t.register(nil, stub(:interval => 1000), nil)
    @t.register(nil, stub(:interval => 800), nil)
    @t.register(nil, stub(:interval => 900), nil)
    @t.register(nil, stub(:interval => 100), nil)
    sleep(0.3)
    assert_equal [100, 800, 900, 1000], @t.events.map { |x| x.condition.interval }
  end
end
