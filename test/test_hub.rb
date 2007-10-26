require File.dirname(__FILE__) + '/helper'

class TestHub < Test::Unit::TestCase
  def setup
    God::Socket.stubs(:new).returns(true)
    God.reset
    
    God.watch do |w|
      w.name = 'foo'
      w.start = 'bar'
      w.interval = 10
    end
    
    @watch = God.watches['foo']
  end
  
  # attach
  
  def test_attach_should_store_condition_metric_association
    c = Conditions::FakePollCondition.new
    m = Metric.new(@watch, :foo)
    Hub.attach(c, m)
    
    assert_equal m, Hub.directory[c]
  end
  
  def test_attach_should_schedule_for_poll_condition
    c = Conditions::FakePollCondition.new
    m = Metric.new(@watch, :foo)
    
    Timer.any_instance.expects(:schedule).with(c, 0)
    
    Hub.attach(c, m)
  end
  
  def test_attach_should_regsiter_for_event_condition
    c = Conditions::FakeEventCondition.new
    m = Metric.new(@watch, :foo)
    
    c.expects(:register)
    
    Hub.attach(c, m)
  end
  
  # detach
  
  def test_detach_should_remove_condition_metric_association
    c = Conditions::FakePollCondition.new
    m = Metric.new(@watch, :foo)
    
    Hub.attach(c, m)
    Hub.detach(c)
    
    assert_nil Hub.directory[c]
  end
  
  def test_detach_should_unschedule_poll_conditions
    c = Conditions::FakePollCondition.new
    m = Metric.new(@watch, :foo)
    Hub.attach(c, m)
    
    Timer.any_instance.expects(:unschedule).with(c)
    c.expects(:deregister).never
    
    Hub.detach(c)
  end
  
  def test_detach_should_deregister_event_conditions
    c = Conditions::FakeEventCondition.new
    m = Metric.new(@watch, :foo)
    Hub.attach(c, m)
    
    c.expects(:deregister).once
    
    Hub.detach(c)
  end
  
  # trigger
  
  def test_trigger_should_handle_poll_for_poll_condition
    c = Conditions::FakePollCondition.new
    Hub.expects(:handle_poll).with(c)
    
    Hub.trigger(c)
  end
  
  def test_trigger_should_handle_event_for_event_condition
    c = Conditions::FakeEventCondition.new
    Hub.expects(:handle_event).with(c)
    
    Hub.trigger(c)
  end
  
  # handle_poll
  
  def test_handle_poll_no_change_should_reschedule
    c = Conditions::FakePollCondition.new
    c.interval = 10
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    c.expects(:test).returns(false)
    Timer.any_instance.expects(:schedule)
    
    no_stdout do
      t = Hub.handle_poll(c)
      t.join
    end
  end
  
  def test_handle_poll_change_should_move
    c = Conditions::FakePollCondition.new
    c.interval = 10
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    c.expects(:test).returns(true)
    @watch.expects(:move).with(:up)
    
    no_stdout do
      t = Hub.handle_poll(c)
      t.join
    end
  end
  
  def test_handle_poll_should_not_abort_on_exception
    c = Conditions::FakePollCondition.new
    c.interval = 10
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    c.expects(:test).raises(StandardError.new)
    
    assert_nothing_raised do
      no_stdout do
        t = Hub.handle_poll(c)
        t.join
      end
    end
  end
  
  def test_handle_poll_should_use_overridden_transition
    c = Conditions::Tries.new
    c.times = 1
    c.transition = :start
    c.prepare
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    @watch.expects(:move).with(:start)
    
    no_stdout do
      t = Hub.handle_poll(c)
      t.join
    end
  end
  
  def test_handle_poll_should_notify_if_triggering
    c = Conditions::FakePollCondition.new
    c.interval = 10
    c.notify = 'tom'
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    c.expects(:test).returns(true)
    Hub.expects(:notify)
    
    no_stdout do
      t = Hub.handle_poll(c)
      t.join
    end
  end
  
  def test_handle_poll_should_not_notify_if_not_triggering
    c = Conditions::FakePollCondition.new
    c.interval = 10
    c.notify = 'tom'
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    c.expects(:test).returns(false)
    Hub.expects(:notify).never
    
    no_stdout do
      t = Hub.handle_poll(c)
      t.join
    end
  end
  
  # handle_event
  
  def test_handle_event_should_move
    c = Conditions::FakeEventCondition.new
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    @watch.expects(:move).with(:up)
    
    no_stdout do
      t = Hub.handle_event(c)
      t.join
    end
  end
  
  def test_handle_event_should_notify_if_triggering
    c = Conditions::FakeEventCondition.new
    c.notify = 'tom'
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    Hub.expects(:notify)
    
    no_stdout do
      t = Hub.handle_event(c)
      t.join
    end
  end
  
  def test_handle_event_should_not_notify_if_no_notify_set
    c = Conditions::FakeEventCondition.new
    
    m = Metric.new(@watch, {true => :up})
    Hub.attach(c, m)
    
    Hub.expects(:notify).never
    
    no_stdout do
      t = Hub.handle_event(c)
      t.join
    end
  end
end