require File.dirname(__FILE__) + '/helper'

class TestProcess < Test::Unit::TestCase
  def setup
    @p = God::Process.new(:name => 'foo')
  end
  
  # These actually excercise call_action in the back at this point - Kev
  def test_call_action_with_string_should_fork_exec 
    @p.start = "do something"
    @p.expects(:fork)
    @p.call_action(:start)
  end
  
  def test_call_action_with_lambda_should_call
    cmd = lambda { puts "Hi" }
    cmd.expects(:call)
    @p.start = cmd
    @p.call_action(:start)
  end
end