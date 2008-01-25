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
    no_stdout do
      assert !@task.valid?
    end
  end
  
  def test_valid_should_return_false_if_no_valid_states
    @task.valid_states = nil
    no_stdout do
      assert !@task.valid?
    end
  end
  
  def test_valid_should_return_false_if_no_initial_state
    @task.initial_state = nil
    no_stdout do
      assert !@task.valid?
    end
  end
  
  # transition
  
  def test_transition_should_be_always_if_no_block_was_given
    @task.transition(:foo, :bar)
    
    assert 1, @task.metrics.size
    assert Conditions::Always, @task.metrics.keys.first.class
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
    Thread.current.stubs(:==).returns(true)
    @task.expects(:system).with('foo')
    no_stdout { @task.action(:foo, nil) }
  end
  
  def test_action_should_call_lambda_commands
    @task.foo = lambda { }
    Thread.current.stubs(:==).returns(true)
    @task.foo.expects(:call)
    no_stdout { @task.action(:foo, nil) }
  end
  
  def test_action_should_raise_not_implemented_on_non_string_or_lambda_action
    Thread.current.stubs(:==).returns(true)
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
end