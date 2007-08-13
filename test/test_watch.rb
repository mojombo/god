require File.dirname(__FILE__) + '/helper'

class TestWatch < Test::Unit::TestCase
  def setup
    @watch = Watch.new
    @watch.name = 'foo'
    @watch.start = lambda { }
    @watch.stop = lambda { }
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
  
  def test_new_should_have_nil_state
    assert_equal nil, @watch.state
  end
  
  # mutex
  
  def test_mutex_should_return_the_same_mutex_each_time
    assert_equal @watch.mutex, @watch.mutex
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
    @watch.expects(:move).with(nil)
    @watch.unmonitor
  end
  
  # move
  
  def test_move_should_not_clean_up_if_from_state_is_nil
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
    
    no_stdout { @watch.move(:init) }
  end
  
  def test_move_should_clean_up_from_state_if_not_nil
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
    
    no_stdout { @watch.move(:init) }
    
    metric.expects(:disable)
    
    no_stdout { @watch.move(:up) }
  end
  
  def test_move_should_call_action
    @watch.expects(:action).with(:start)
    
    no_stdout { @watch.move(:start) }
  end
  
  def test_move_should_move_to_up_state_if_no_start_or_restart_metric
    [:start, :restart].each do |state|
      @watch.expects(:action)
      no_stdout { @watch.move(state) }
      assert_equal :up, @watch.state
    end
  end
  
  def test_move_should_enable_destination_metric
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
    
    no_stdout { @watch.move(:init) }
  end
  
  # action
  
  def test_action_should_pass_start_and_stop_actions_to_call_action
    c = Conditions::FakePollCondition.new
    [:start, :stop].each do |cmd|
      @watch.expects(:call_action).with(c, cmd)
      no_stdout { @watch.action(cmd, c) }
    end
  end
  
  def test_action_should_do_stop_then_start_if_no_restart_command
    c = Conditions::FakePollCondition.new
    @watch.expects(:call_action).with(c, :stop)
    @watch.expects(:call_action).with(c, :start)
    no_stdout { @watch.action(:restart, c) }
  end
  
  def test_action_should_restart_to_call_action_if_present
    @watch.restart = lambda { }
    c = Conditions::FakePollCondition.new
    @watch.expects(:call_action).with(c, :restart)
    no_stdout { @watch.action(:restart, c) }
  end
  
  # call_action
  
  def test_call_action
    c = Conditions::FakePollCondition.new
    God::Process.any_instance.expects(:call_action).with(:start)
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