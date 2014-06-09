require File.dirname(__FILE__) + '/helper'

class TestDriver < Test::Unit::TestCase
  def setup

  end

  def test_push_pop_wait
    eq = God::DriverEventQueue.new

    MonitorMixin::ConditionVariable.any_instance.expects(:wait).times(1)

    eq.push(God::TimedEvent.new(0))
    eq.push(God::TimedEvent.new(0.1))
    t = Thread.new do
      # This pop will see an event immediately available, so no wait.
      assert_equal TimedEvent, eq.pop.class

      # This pop will happen before the next event is due, so wait.
      assert_equal TimedEvent, eq.pop.class
    end

    t.join
  end

  def test_timed_event_signals
    event = God::TimedEvent.new(0)

    queue = []

    Thread.new do
      sleep(0.1)
      event.done
    end

    event.wait(0.1)
  end

  def test_timeouts
    event = God::TimedEvent.new(0)
    event.wait(0.1)
    flunk
  rescue WaitTimeout
    # Pass
  end

  def test_nil_wait_value
    event = God::TimedEvent.new(0)
    event.wait(nil)
  end
end
