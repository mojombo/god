require File.dirname(__FILE__) + '/helper'

class BadlyImplementedCondition < PollCondition
end

class TestCondition < Test::Unit::TestCase

  # generate

  def test_generate_should_return_an_object_corresponding_to_the_given_type
    assert_equal Conditions::ProcessRunning, Condition.generate(:process_running, nil).class
  end

  def test_generate_should_raise_on_invalid_type
    assert_raise NoSuchConditionError do
      Condition.generate(:foo, nil)
    end
  end

  def test_generate_should_abort_on_event_condition_without_loaded_event_system
    God::EventHandler.stubs(:operational?).returns(false)
    assert_abort do
      God::EventHandler.start
      Condition.generate(:process_exits, nil).class
    end
  end

  def test_generate_should_return_a_good_error_message_for_invalid_types
    emsg = "No Condition found with the class name God::Conditions::FooBar"
    rmsg = nil

    begin
      Condition.generate(:foo_bar, nil)
    rescue => e
      rmsg = e.message
    end

    assert_equal emsg, rmsg
  end

  # test

  def test_test_should_raise_if_not_defined_in_subclass
    c = BadlyImplementedCondition.new

    assert_raise AbstractMethodNotOverriddenError do
      c.test
    end
  end
end
