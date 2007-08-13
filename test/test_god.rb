require File.dirname(__FILE__) + '/helper'

class TestGod < Test::Unit::TestCase
  def setup
    Server.stubs(:new).returns(true)
    God.reset
  end
  
  def teardown
    Timer.get.timer.kill
  end
  
  # init
  
  def test_init_should_initialize_watches_to_empty_array
    God.init { }
    assert_equal Hash.new, God.watches
  end
  
  def test_init_should_kick_off_a_server_instance
    Server.expects(:new).returns(true)
    God.init
  end
  
  # pid_file_directory
  
  def test_pid_file_directory_should_return_default_if_not_set_explicitly
    assert_equal '/var/run/god', God.pid_file_directory
  end
  
  def test_pid_file_directory_equals_should_set
    God.pid_file_directory = '/foo'
    assert_equal '/foo', God.pid_file_directory
  end
  
  # watch
  
  def test_watch_should_get_stored
    watch = nil
    God.watch { |w| watch = w }
    
    assert_equal 1, God.watches.size
    assert_equal watch, God.watches.values.first
    
    assert_equal 0, God.groups.size
  end
  
  def test_watch_should_register_processes
    assert_nil God.registry['foo']
    God.watch { |w| w.name = 'foo' }
    assert_kind_of God::Process, God.registry['foo']
  end
  
  def test_watch_should_get_stored_by_group
    God.watch do |w|
      w.name = 'foo'
      w.group = 'test'
    end
    
    assert_equal({'test' => ['foo']}, God.groups)
  end
  
  def test_watches_should_get_stored_by_group
    God.watch do |w|
      w.name = 'foo'
      w.group = 'test'
    end
    
    God.watch do |w|
      w.name = 'bar'
      w.group = 'test'
    end
    
    assert_equal({'test' => ['foo', 'bar']}, God.groups)
  end
      
  def test_watch_should_allow_multiple_watches
    God.watch { |w| w.name = 'foo' }
    
    assert_nothing_raised do
      God.watch { |w| w.name = 'bar' }
    end
  end
  
  def test_watch_should_disallow_duplicate_watch_names
    God.watch { |w| w.name = 'foo' }
    
    assert_abort do
      God.watch { |w| w.name = 'foo' }
    end
  end
  
  def test_watch_should_disallow_identical_watch_and_group_names
    God.watch { |w| w.name = 'foo'; w.group = 'bar' }
    
    assert_abort do
      God.watch { |w| w.name = 'bar' }
    end
  end
  
  def test_watch_should_disallow_identical_watch_and_group_names_other_way
    God.watch { |w| w.name = 'bar' }
    
    assert_abort do
      God.watch { |w| w.name = 'foo'; w.group = 'bar' }
    end
  end
  
  # control
  
  def test_control_should_monitor_on_start
    God.watch { |w| w.name = 'foo' }
    
    w = God.watches['foo']
    w.expects(:monitor)
    God.control('foo', 'start')
  end
  
  def test_control_should_move_to_restart_on_restart
    God.watch { |w| w.name = 'foo' }
    
    w = God.watches['foo']
    w.expects(:move).with(:restart)
    God.control('foo', 'restart')
  end
  
  def test_control_should_unmonitor_and_stop_on_stop
    God.watch { |w| w.name = 'foo' }
    
    w = God.watches['foo']
    w.expects(:unmonitor).returns(w)
    w.expects(:action).with(:stop)
    God.control('foo', 'stop')
  end
  
  def test_control_should_unmonitor_on_unmonitor
    God.watch { |w| w.name = 'foo' }
    
    w = God.watches['foo']
    w.expects(:unmonitor).returns(w)
    God.control('foo', 'unmonitor')
  end
  
  def test_control_should_raise_on_invalid_command
    God.watch { |w| w.name = 'foo' }
    
    assert_raise InvalidCommandError do
      God.control('foo', 'invalid')
    end
  end
  
  # start
  
  def test_start_should_check_for_at_least_one_watch
    assert_abort do
      God.start
    end
  end
  
  def test_start_should_start_event_handler
    God.watch { |w| w.name = 'foo' }
    Timer.any_instance.expects(:join)
    EventHandler.expects(:start).once
    no_stdout do
      God.start
    end
  end
  
  def test_start_should_begin_monitoring_autostart_watches
    God.watch do |w|
      w.name = 'foo'
    end
    
    Timer.any_instance.expects(:join)
    Watch.any_instance.expects(:monitor).once
    God.start
  end
  
  def test_start_should_not_begin_monitoring_non_autostart_watches
    God.watch do |w|
      w.name = 'foo'
      w.autostart = false
    end
    
    Timer.any_instance.expects(:join)
    Watch.any_instance.expects(:monitor).never
    God.start
  end
  
  def test_start_should_get_and_join_timer
    God.watch { |w| w.name = 'foo' }
    Timer.any_instance.expects(:join)
    no_stdout do
      God.start
    end
  end
  
  # at_exit
  
  def test_at_exit_should_call_start
    God.expects(:start).once
    God.at_exit_orig
  end
  
  # load
  
  def test_load_should_collect_and_load_globbed_path
    Dir.expects(:[]).with('/path/to/*.thing').returns(['a', 'b'])
    Kernel.expects(:load).with('a').once
    Kernel.expects(:load).with('b').once
    God.load('/path/to/*.thing')
  end
end
