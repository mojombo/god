require File.dirname(__FILE__) + '/helper'

module God
  class EventHandler

    def self.actions=(value)
      @@actions = value
    end

    def self.actions
      @@actions
    end

    def self.handler=(value)
      @@handler = value
    end
  end
end

class TestEventHandler < Test::Unit::TestCase
  def setup
    @h = God::EventHandler
  end

  def test_register_one_event
    pid = 4445
    event = :proc_exit
    block = lambda {
      puts "Hi"
    }

    mock_handler = mock()
    mock_handler.expects(:register_process).with(pid, [event])
    @h.handler = mock_handler

    @h.register(pid, event, &block)
    assert_equal @h.actions, {pid => {event => block}}
  end

  def test_register_multiple_events_per_process
    pid = 4445
    exit_block = lambda { puts "Hi" }
    @h.actions = {pid => {:proc_exit => exit_block}}

    mock_handler = mock()
    mock_handler.expects(:register_process).with do |a, b|
      a == pid &&
      b.to_set == [:proc_exit, :proc_fork].to_set
    end
    @h.handler = mock_handler

    fork_block = lambda { puts "Forking" }
    @h.register(pid, :proc_fork, &fork_block)
    assert_equal @h.actions, {pid => {:proc_exit => exit_block,
                                     :proc_fork => fork_block }}
  end

  # JIRA PLATFORM-75
  def test_call_should_check_for_pid_and_action_before_executing
    exit_block = mock()
    exit_block.expects(:call).times 1
    @h.actions = {4445 => {:proc_exit => exit_block}}
    @h.call(4446, :proc_exit) # shouldn't call, bad pid
    @h.call(4445, :proc_fork) # shouldn't call, bad event
    @h.call(4445, :proc_exit) # should call
  end

  def teardown
    # Reset handler
    @h.actions = {}
    @h.load
  end
end

class TestEventHandlerOperational < Test::Unit::TestCase
  def test_operational
    God::EventHandler.start
    assert God::EventHandler.loaded?
  end
end
