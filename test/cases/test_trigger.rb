require File.dirname(__FILE__) + '/helper'

class TestTrigger < Test::Unit::TestCase
  def setup
    Trigger.reset
  end
  
  # base case
  
  def test_should_have_empty_triggers
    assert_equal({}, Trigger.triggers)
  end
  
  # register
  
  def test_register_should_add_condition_to_triggers
    c = Condition.new
    c.watch = stub(:name => 'foo')
    Trigger.register(c)
    
    assert_equal({'foo' => [c]}, Trigger.triggers)
  end
  
  def test_register_should_add_condition_to_triggers_twice
    watch = stub(:name => 'foo')
    c = Condition.new
    c.watch = watch
    Trigger.register(c)
    
    c2 = Condition.new
    c2.watch = watch
    Trigger.register(c2)
    
    assert_equal({'foo' => [c, c2]}, Trigger.triggers)
  end
  
  # deregister
  
  def test_deregister_should_remove_condition_from_triggers
    c = Condition.new
    c.watch = stub(:name => 'foo')
    Trigger.register(c)
    Trigger.deregister(c)
    
    assert_equal({}, Trigger.triggers)
  end
  
  # broadcast
  
  def test_broadcast_should_call_process_on_each_condition
    c = Condition.new
    c.watch = stub(:name => 'foo')
    Trigger.register(c)
    
    c.expects(:process).with(:state_change, [:up, :start])
    
    Trigger.broadcast(c.watch, :state_change, [:up, :start])
  end
end