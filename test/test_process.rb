require File.dirname(__FILE__) + '/helper'

module God
  class Process
    def fork
      raise "You forgot to stub fork"
    end
    
    def exec(*args)
      raise "You forgot to stub exec"
    end
  end
end

class TestProcess < Test::Unit::TestCase
  def setup
    @p = God::Process.new(:name => 'foo', :pid_file => 'blah.pid')
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

  def test_default_pid_file
    assert_equal File.join(God.pid_file_directory, 'foo.pid'), @p.default_pid_file
  end
  
  def test_call_action_without_pid_should_write_pid
    # Only for start, restart
    [:start, :restart].each do |action|
      @p = God::Process.new(:name => 'foo')
      @p.expects(:fork)
      File.expects(:open).with(@p.default_pid_file, 'w')
      @p.send("#{action}=", "run")
      @p.call_action(action)
    end
  end
  
  def test_call_action_should_not_write_pid_for_stop
    @p.pid_file = nil
    @p.expects(:fork)
    File.expects(:open).times(0)
    @p.stop = "stopping"
    @p.call_action(:stop)
  end
end