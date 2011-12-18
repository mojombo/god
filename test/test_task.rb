require File.dirname(__FILE__) + '/helper'

class TestTask < Test::Unit::TestCase
  def setup
    God.internal_init
    @task = Task.new
    @task.name = 'foo'
    @task.valid_states = [:foo, :bar]
    @task.initial_state = :foo
    @task.interval = 5
    @task.prepare
  end

  # valid?

  def test_valid_should_return_false_if_no_name
    @task.name = nil
    assert !@task.valid?
  end

  def test_valid_should_return_false_if_no_valid_states
    @task.valid_states = nil
    assert !@task.valid?
  end

  def test_valid_should_return_false_if_no_initial_state
    @task.initial_state = nil
    assert !@task.valid?
  end

  # transition

  def test_transition_should_be_always_if_no_block_was_given
    @task.transition(:foo, :bar)

    assert_equal 5, @task.metrics.size
    assert_equal Conditions::Always, @task.metrics[:foo].first.conditions.first.class
  end

  # method_missing

  def test_method_missing_should_create_accessor_for_states
    assert_nothing_raised do
      @task.foo = 'testing'
    end
  end

  def test_method_missing_should_raise_for_non_states
    assert_raise NoMethodError do
      @task.baz = 5
    end
  end

  def test_method_missing_should_raise_for_non_setters
    assert_raise NoMethodError do
      @task.baz
    end
  end

  # action

  def test_action_should_send_string_commands_to_system
    @task.foo = 'foo'
    @task.driver.stubs(:in_driver_context?).returns(true)
    @task.expects(:system).with('foo')
    @task.action(:foo, nil)
  end

  def test_action_should_call_lambda_commands
    @task.foo = lambda { }
    @task.driver.stubs(:in_driver_context?).returns(true)
    @task.foo.expects(:call)
    @task.action(:foo, nil)
  end

  def test_action_should_raise_not_implemented_on_non_string_or_lambda_action
    @task.driver.stubs(:in_driver_context?).returns(true)
    assert_raise NotImplementedError do
      @task.foo = 7
      @task.action(:foo, nil)
    end
  end

  def test_action_from_outside_driver_should_send_message_to_driver
    @task.foo = 'foo'
    @task.driver.expects(:message).with(:action, [:foo, nil])
    @task.action(:foo, nil)
  end

  # attach

  def test_attach_should_schedule_for_poll_condition
    c = Conditions::FakePollCondition.new
    @task.driver.expects(:schedule).with(c, 0)
    @task.attach(c)
  end

  def test_attach_should_regsiter_for_event_condition
    c = Conditions::FakeEventCondition.new
    c.expects(:register)
    @task.attach(c)
  end

  # detach

  def test_detach_should_reset_poll_condition
    c = Conditions::FakePollCondition.new
    c.expects(:reset)
    c.expects(:deregister).never
    @task.detach(c)
  end

  def test_detach_should_deregister_event_conditions
    c = Conditions::FakeEventCondition.new
    c.expects(:deregister).once
    @task.detach(c)
  end

  # trigger

  def test_trigger_should_send_message_to_driver
    c = Conditions::FakePollCondition.new
    @task.driver.expects(:message).with(:handle_event, [c])
    @task.trigger(c)
  end

  # handle_poll

  def test_handle_poll_no_change_should_reschedule
    c = Conditions::FakePollCondition.new
    c.watch = @task
    c.interval = 10

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    c.expects(:test).returns(false)
    @task.driver.expects(:schedule)
    @task.handle_poll(c)
  end

  def test_handle_poll_change_should_move
    c = Conditions::FakePollCondition.new
    c.watch = @task
    c.interval = 10

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    c.expects(:test).returns(true)
    @task.expects(:move).with(:up)
    @task.handle_poll(c)
  end

  def test_handle_poll_should_use_overridden_transition
    c = Conditions::Tries.new
    c.watch = @task
    c.times = 1
    c.transition = :start
    c.prepare

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    @task.expects(:move).with(:start)
    @task.handle_poll(c)
  end

  def test_handle_poll_should_notify_if_triggering
    c = Conditions::FakePollCondition.new
    c.watch = @task
    c.interval = 10
    c.notify = 'tom'

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    c.expects(:test).returns(true)
    @task.expects(:notify)
    @task.handle_poll(c)
  end

  def test_handle_poll_should_not_notify_if_not_triggering
    c = Conditions::FakePollCondition.new
    c.watch = @task
    c.interval = 10
    c.notify = 'tom'

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    c.expects(:test).returns(false)
    @task.expects(:notify).never
    @task.handle_poll(c)
  end

  def test_handle_poll_unexpected_exception_should_reschedule
    c = Conditions::FakePollCondition.new
    c.watch = @task
    c.interval = 10

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    c.expects(:test).raises(StandardError)
    @task.driver.expects(:schedule)

    @task.handle_poll(c)
  end

  # handle_event

  def test_handle_event_should_move
    c = Conditions::FakeEventCondition.new
    c.watch = @task

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    @task.expects(:move).with(:up)
    @task.handle_event(c)
  end

  def test_handle_event_should_notify_if_triggering
    c = Conditions::FakeEventCondition.new
    c.watch = @task
    c.notify = 'tom'

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    @task.expects(:notify)
    @task.handle_event(c)
  end

  def test_handle_event_should_not_notify_if_no_notify_set
    c = Conditions::FakeEventCondition.new
    c.watch = @task

    m = Metric.new(@task, {true => :up})
    @task.directory[c] = m

    @task.expects(:notify).never
    @task.handle_event(c)
  end
end
