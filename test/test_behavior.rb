require File.dirname(__FILE__) + '/helper'

class TestBehavior < Test::Unit::TestCase
  def test_generate_should_return_an_object_corresponding_to_the_given_type
    assert_equal Behaviors::FakeBehavior, Behavior.generate(:fake_behavior).class
  end
  
  def test_generate_should_raise_on_invalid_type
    assert_raise NoSuchBehaviorError do
      Behavior.generate(:foo)
    end
  end
end