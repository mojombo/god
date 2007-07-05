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
    
    @t.register('foo', 20)
    
    assert_equal 1, @t.events.size
    assert_equal 'foo', @t.events.keys.first
    assert_equal 20, @t.events['foo']
  end
  
  def test_timer_should_remove_expired_events
    @t.register('foo', 0)
    sleep(0.3)
    assert_equal 0, @t.events.size
  end
  
  def test_timer_should_remove_only_expired_events
    @t.register('foo', 0)
    @t.register('bar', 1000)
    sleep(0.3)
    assert_equal 1, @t.events.size
  end
end
