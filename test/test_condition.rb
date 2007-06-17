require File.dirname(__FILE__) + '/helper'

class TestCondition < Test::Unit::TestCase
  def test_generate_should_return_an_object_corresponding_to_the_given_type
    assert_equal Conditions::ProcessNotRunning, Condition.generate(:process_not_running).class
  end
  
  def test_generate_should_raise_on_invalid_type
    assert_raise NoSuchConditionError do
      Condition.generate(:foo)
    end
  end
  
  def test_generate_should_return_a_good_error_message_for_invalid_types
    emsg = "No Condition found with the class name God::Conditions::FooBar"
    rmsg = nil
    
    begin
      Condition.generate(:foo_bar)
    rescue => e
      rmsg = e.message
    end
    
    assert_equal emsg, rmsg
  end
end
