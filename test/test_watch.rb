require File.dirname(__FILE__) + '/helper'

class TestWatch < Test::Unit::TestCase
  def setup
    God.internal_init
    @watch = Watch.new
    @watch.name = 'foo'
    @watch.start = lambda { }
    @watch.stop = lambda { }
    @watch.prepare
  end

  # new

  def test_new_should_have_no_behaviors
    assert_equal [], @watch.behaviors
  end

  def test_new_should_have_no_metrics
    Watch::VALID_STATES.each do |state|
      assert_equal [], @watch.metrics[state]
    end
  end

  def test_new_should_have_standard_attributes
    assert_nothing_raised do
      @watch.name = 'foo'
      @watch.start = 'start'
      @watch.stop = 'stop'
      @watch.restart = 'restart'
      @watch.interval = 30
      @watch.grace = 5
    end
  end

  def test_new_should_have_unmonitored_state
    assert_equal :unmonitored, @watch.state
  end

  # valid?

  def test_valid?
    God::Process.any_instance.expects(:valid?)
    @watch.valid?
  end

  # behavior

  def test_behavior_should_record_behavior
    beh = nil
    @watch.behavior(:fake_behavior) { |b| beh = b }
    assert_equal 1, @watch.behaviors.size
    assert_equal beh, @watch.behaviors.first
  end

  def test_invalid_behavior_should_abort
    assert_abort do
      @watch.behavior(:invalid)
    end
  end

  # transition

  def test_transition_should_abort_on_invalid_start_state
    assert_abort do
      @watch.transition(:foo, :bar)
    end
  end

  def test_transition_should_accept_all_valid_start_states
    assert_nothing_raised do
      Watch::VALID_STATES.each do |state|
        @watch.transition(state, :bar) { }
      end
    end
  end

  def test_transition_should_create_and_record_a_metric_for_the_given_start_state
    @watch.transition(:init, :start) { }
    assert_equal 1, @watch.metrics[:init].size
  end

  # lifecycle

  def test_lifecycle_should_create_and_record_a_metric_for_nil_start_state
    @watch.lifecycle { }
    assert_equal 1, @watch.metrics[nil].size
  end

  # keepalive

  def test_keepalive_should_place_metrics_on_up_state
    @watch.keepalive(:memory_max => 5.megabytes, :cpu_max => 50.percent)
    assert_equal 2, @watch.metrics[:up].size
  end

  # start_if

  def test_start_if_should_place_a_metric_on_up_state
    @watch.start_if { }
    assert_equal 1, @watch.metrics[:up].size
  end

  # restart_if

  def test_restart_if_should_place_a_metric_on_up_state
    @watch.restart_if { }
    assert_equal 1, @watch.metrics[:up].size
  end

  # monitor

  def test_monitor_should_move_to_init_if_available
    @watch.instance_eval do
      transition(:init, :up) { }
    end
    @watch.expects(:move).with(:init)
    @watch.monitor
  end

  def test_monitor_should_move_to_up_if_no_init_available
    @watch.expects(:move).with(:up)
    @watch.monitor
  end

  # unmonitor

  def test_unmonitor_should_move_to_nil
    @watch.expects(:move).with(:unmonitored)
    @watch.unmonitor
  end

  # move

  def test_move_should_not_clean_up_if_from_state_is_nil
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    metric = nil

    @watch.instance_eval do
      transition(:init, :up) do |on|
        metric = on
        on.condition(:process_running) do |c|
          c.running = true
          c.interval = 10
        end
      end
    end

    metric.expects(:disable).never

    @watch.move(:init)
  end

  def test_move_should_clean_up_from_state_if_not_nil
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    metric = nil

    @watch.instance_eval do
      transition(:init, :up) do |on|
        metric = on
        on.condition(:process_running) do |c|
          c.running = true
          c.interval = 10
        end
      end
    end

    @watch.move(:init)

    metric.expects(:disable)

    @watch.move(:up)
  end

  def test_move_should_call_action
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    @watch.expects(:action).with(:start)

    @watch.move(:start)
  end

  def test_move_should_move_to_up_state_if_no_start_or_restart_metric
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    [:start, :restart].each do |state|
      @watch.expects(:action)
      @watch.move(state)
      assert_equal :up, @watch.state
    end
  end

  def test_move_should_enable_destination_metric
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    metric = nil

    @watch.instance_eval do
      transition(:init, :up) do |on|
        metric = on
        on.condition(:process_running) do |c|
          c.running = true
          c.interval = 10
        end
      end
    end

    metric.expects(:enable)

    @watch.move(:init)
  end

  # action

  def test_action_should_pass_start_and_stop_actions_to_call_action
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    c = Conditions::FakePollCondition.new
    [:start, :stop].each do |cmd|
      @watch.expects(:call_action).with(c, cmd)
      @watch.action(cmd, c)
    end
  end

  def test_action_should_do_stop_then_start_if_no_restart_command
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    c = Conditions::FakePollCondition.new
    @watch.expects(:call_action).with(c, :stop)
    @watch.expects(:call_action).with(c, :start)
    @watch.action(:restart, c)
  end

  def test_action_should_restart_to_call_action_if_present
    @watch.driver.stubs(:in_driver_context?).returns(true)
    @watch.driver.expects(:message).never

    @watch.restart = lambda { }
    c = Conditions::FakePollCondition.new
    @watch.expects(:call_action).with(c, :restart)
    @watch.action(:restart, c)
  end

  # call_action

  def test_call_action
    c = Conditions::FakePollCondition.new
    God::Process.any_instance.expects(:call_action).with(:start)
    @watch.call_action(c, :start)
  end

  def test_call_action_should_call_before_start_when_behavior_has_that
    @watch.behavior(:fake_behavior)
    c = Conditions::FakePollCondition.new
    God::Process.any_instance.expects(:call_action).with(:start)
    Behaviors::FakeBehavior.any_instance.expects(:before_start)
    @watch.call_action(c, :start)
  end

  def test_call_action_should_call_after_start_when_behavior_has_that
    @watch.behavior(:fake_behavior)
    c = Conditions::FakePollCondition.new
    God::Process.any_instance.expects(:call_action).with(:start)
    Behaviors::FakeBehavior.any_instance.expects(:after_start)
    @watch.call_action(c, :start)
  end

  # canonical_hash_form

  def test_canonical_hash_form_should_convert_symbol_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(:foo))
  end

  def test_canonical_hash_form_should_convert_hash_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(true => :foo))
  end
end
