require File.dirname(__FILE__) + '/helper'

class TestBehavior < Test::Unit::TestCase
  def test_generate_should_return_an_object_corresponding_to_the_given_type
    assert_equal Behaviors::FakeBehavior, Behavior.generate(:fake_behavior, nil).class
  end
  
  def test_generate_should_raise_on_invalid_type
    assert_raise NoSuchBehaviorError do
      Behavior.generate(:foo, nil)
    end
  end
  
  def test_complain
    Syslog.expects(:err).with('foo')
    # Kernel.expects(:puts).with('foo')
    no_stdout do
      assert !Behavior.allocate.bypass.complain('foo')
    end
  end
end