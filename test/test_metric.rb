require File.dirname(__FILE__) + '/helper'

class TestMetric < Test::Unit::TestCase
  def setup
    @metric = Metric.new(stub(:interval => 10), nil)
  end
  
  # watch
  
  def test_watch
    w = stub()
    m = Metric.new(w, nil)
    assert_equal w, m.watch
  end
  
  # destination
  
  def test_destination
    d = stub()
    m = Metric.new(nil, d)
    assert_equal d, m.destination
  end
  
  # condition
  
  def test_condition_should_be_block_optional
    @metric.condition(:fake_poll_condition)
    assert_equal 1, @metric.conditions.size
  end
  
  def test_poll_condition_should_inherit_interval_from_watch_if_not_specified
    @metric.condition(:fake_poll_condition)
    assert_equal 10, @metric.conditions.first.interval
  end
  
  def test_poll_condition_should_abort_if_no_interval_and_no_watch_interval
    metric = Metric.new(stub(:interval => nil), nil)
    
    assert_raise AbortCalledError do
      metric.condition(:fake_poll_condition)
    end
  end
  
  def test_condition_should_allow_generation_of_subclasses_of_poll_or_event
    @watch.interval = 27
    assert_nothing_raised do
      @watch.start_if do |w|
        w.condition(:fake_poll_condition)
        w.condition(:fake_event_condition)
      end
    end
  end
  
  def test_condition_should_abort_if_not_subclass_of_poll_or_event
    assert_raise AbortCalledError do
      @watch.start_if do |w|
        w.condition(:fake_condition) { |c| }
      end
    end
  end
end