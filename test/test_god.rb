require File.dirname(__FILE__) + '/helper'

class TestGod < Test::Unit::TestCase
  def setup
    God::Socket.stubs(:new).returns(true)
    God.stubs(:setup).returns(true)
    God.stubs(:validater).returns(true)
    God.reset
    God.pid_file_directory = '/var/run/god'
  end

  def teardown
    God.main && God.main.kill
    if God.watches
      God.watches.each do |k, w|
        w.driver.thread.kill
      end
    end
  end

  # applog

  def test_applog
    LOG.expects(:log).with(nil, :debug, 'foo')
    applog(nil, :debug, 'foo')
  end

  # internal_init

  def test_init_should_initialize_watches_to_empty_array
    God.internal_init { }
    assert_equal Hash.new, God.watches
  end

  # init

  def test_pid_file_directory_should_abort_if_called_after_watch
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    assert_abort do
      God.pid_file_directory = 'foo'
    end
  end

  # pid_file_directory

  def test_pid_file_directory_should_return_default_if_not_set_explicitly
    God.internal_init
    assert_equal '/var/run/god', God.pid_file_directory
  end

  def test_pid_file_directory_equals_should_set
    God.pid_file_directory = '/foo'
    God.internal_init
    assert_equal '/foo', God.pid_file_directory
  end

  # watch

  def test_watch_should_get_stored
    watch = nil
    God.watch do |w|
      w.name = 'foo'
      w.start = 'bar'
      watch = w
    end

    assert_equal 1, God.watches.size
    assert_equal watch, God.watches.values.first

    assert_equal 0, God.groups.size
  end

  def test_watch_should_get_stored_in_pending_watches
    watch = nil
    God.watch do |w|
      w.name = 'foo'
      w.start = 'bar'
      watch = w
    end

    assert_equal 1, God.pending_watches.size
    assert_equal watch, God.pending_watches.first
  end

  def test_watch_should_register_processes
    assert_nil God.registry['foo']
    God.watch do |w|
      w.name = 'foo'
      w.start = 'bar'
    end
    assert_kind_of God::Process, God.registry['foo']
  end

  def test_watch_should_get_stored_by_group
    a = nil

    God.watch do |w|
      a = w
      w.name = 'foo'
      w.start = 'bar'
      w.group = 'test'
    end

    assert_equal({'test' => [a]}, God.groups)
  end

  def test_watches_should_get_stored_by_group
    a = nil
    b = nil

    God.watch do |w|
      a = w
      w.name = 'foo'
      w.start = 'bar'
      w.group = 'test'
    end

    God.watch do |w|
      b = w
      w.name = 'bar'
      w.start = 'baz'
      w.group = 'test'
    end

    assert_equal({'test' => [a, b]}, God.groups)
  end

  def test_watch_should_allow_multiple_watches
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    assert_nothing_raised do
      God.watch { |w| w.name = 'bar'; w.start = 'bar' }
    end
  end

  def test_watch_should_disallow_duplicate_watch_names
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    assert_abort do
      God.watch { |w| w.name = 'foo'; w.start = 'bar' }
    end
  end

  def test_watch_should_disallow_identical_watch_and_group_names
    God.watch { |w| w.name = 'foo'; w.group = 'bar'; w.start = 'bar' }

    assert_abort do
      God.watch { |w| w.name = 'bar'; w.start = 'bar' }
    end
  end

  def test_watch_should_disallow_identical_watch_and_group_names_other_way
    God.watch { |w| w.name = 'bar'; w.start = 'bar' }

    assert_abort do
      God.watch { |w| w.name = 'foo'; w.group = 'bar'; w.start = 'bar' }
    end
  end

  def test_watch_should_unwatch_new_watch_if_running_and_duplicate_watch
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }
    God.running = true

    assert_nothing_raised do
      God.watch { |w| w.name = 'foo'; w.start = 'bar' }
    end
  end

  # unwatch

  def test_unwatch_should_unmonitor_watch
    God.watch { |w| w.name = 'bar'; w.start = 'bar' }
    w = God.watches['bar']
    w.state = :up
    w.expects(:unmonitor)
    God.unwatch(w)
  end

  def test_unwatch_should_unregister_watch
    God.watch { |w| w.name = 'bar'; w.start = 'bar' }
    w = God.watches['bar']
    w.expects(:unregister!)
    God.unwatch(w)
  end

  def test_unwatch_should_remove_same_name_watches
    God.watch { |w| w.name = 'bar'; w.start = 'bar' }
    w = God.watches['bar']
    God.unwatch(w)
    assert_equal 0, God.watches.size
  end

  def test_unwatch_should_remove_from_group
    God.watch do |w|
      w.name = 'bar'
      w.start = 'baz'
      w.group = 'test'
    end
    w = God.watches['bar']
    God.unwatch(w)
    assert !God.groups[w.group].include?(w)
  end

  # contact

  def test_contact_should_ensure_init_is_called
    God.contact(:fake_contact) { |c| c.name = 'tom' }
    assert God.inited
  end

  def test_contact_should_abort_on_invalid_contact_kind
    assert_abort do
      God.contact(:foo) { |c| c.name = 'tom' }
    end
  end

  def test_contact_should_create_and_store_contact
    contact = nil
    God.contact(:fake_contact) { |c| c.name = 'tom'; contact = c }
    assert_equal({"tom" => contact}, God.contacts)
  end

  def test_contact_should_add_to_group
    God.contact(:fake_contact) { |c| c.name = 'tom'; c.group = 'devs' }
    God.contact(:fake_contact) { |c| c.name = 'chris'; c.group = 'devs' }
    assert_equal 2, God.contacts.size
    assert_equal 1, God.contact_groups.size
  end

  def test_contact_should_abort_on_no_name
    assert_abort do
      God.contact(:fake_contact) { |c| }
    end
  end

  def test_contact_should_abort_on_duplicate_contact_name
    God.contact(:fake_contact) { |c| c.name = 'tom' }
    assert_nothing_raised do
      God.contact(:fake_contact) { |c| c.name = 'tom' }
    end
  end

  def test_contact_should_abort_on_contact_with_same_name_as_group
    God.contact(:fake_contact) { |c| c.name = 'tom'; c.group = 'devs' }
    assert_nothing_raised do
      God.contact(:fake_contact) { |c| c.name = 'devs' }
    end
  end

  def test_contact_should_abort_on_contact_with_same_group_as_name
    God.contact(:fake_contact) { |c| c.name = 'tom' }
    assert_abort do
      God.contact(:fake_contact) { |c| c.name = 'chris'; c.group = 'tom' }
    end
  end

  def test_contact_should_abort_if_contact_is_invalid
    assert_abort do
      God.contact(:fake_contact) do |c|
        c.name = 'tom'
        c.stubs(:valid?).returns(false)
      end
    end
  end

  # control

  def test_control_should_monitor_on_start
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.expects(:monitor)
    God.control('foo', 'start')
  end

  def test_control_should_move_to_restart_on_restart
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.expects(:move).with(:restart)
    God.control('foo', 'restart')
  end

  def test_control_should_unmonitor_and_stop_on_stop
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.state = :up
    w.expects(:unmonitor).returns(w)
    w.expects(:action).with(:stop)
    God.control('foo', 'stop')
  end

  def test_control_should_unmonitor_on_unmonitor
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.state = :up
    w.expects(:unmonitor).returns(w)
    God.control('foo', 'unmonitor')
  end

  def test_control_should_unwatch_on_remove
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.state = :up
    God.expects(:unwatch)
    God.control('foo', 'remove')
  end

  def test_control_should_raise_on_invalid_command
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    assert_raise InvalidCommandError do
      God.control('foo', 'invalid')
    end
  end

  def test_control_should_operate_on_each_watch_in_group
    God.watch do |w|
      w.name = 'foo1'
      w.start = 'go'
      w.group = 'bar'
    end

    God.watch do |w|
      w.name = 'foo2'
      w.start = 'go'
      w.group = 'bar'
    end

    God.watches['foo1'].expects(:monitor)
    God.watches['foo2'].expects(:monitor)

    God.control('bar', 'start')
  end

  # stop_all

  # terminate

  def test_terminate_should_exit
    God.pid = nil
    FileUtils.expects(:rm_f).never
    God.expects(:exit!)
    God.terminate
  end

  def test_terminate_should_delete_pid
    God.pid = '/foo/bar'
    FileUtils.expects(:rm_f).with("/foo/bar")
    God.expects(:exit!)
    God.terminate
  end

  # status

  def test_status_should_show_state
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    w.state = :up
    assert_equal({'foo' => {:state => :up, :group => nil}}, God.status)
  end

  def test_status_should_show_state_with_group
    God.watch { |w| w.name = 'foo'; w.start = 'bar'; w.group = 'g' }

    w = God.watches['foo']
    w.state = :up
    assert_equal({'foo' => {:state => :up, :group => 'g'}}, God.status)
  end

  def test_status_should_show_unmonitored_for_nil_state
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }

    w = God.watches['foo']
    assert_equal({'foo' => {:state => :unmonitored, :group => nil}}, God.status)
  end

  # running_log

  def test_running_log_should_call_watch_log_since_on_main_log
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }
    t = Time.now
    LOG.expects(:watch_log_since).with('foo', t)
    God.running_log('foo', t)
  end

  def test_running_log_should_raise_on_unknown_watch
    God.internal_init
    assert_raise(NoSuchWatchError) do
      God.running_log('foo', Time.now)
    end
  end

  # running_load

  def test_running_load_should_eval_code
    code = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    God.running_load(code, '/foo/bar.god')

    assert_equal 1, God.watches.size
  end

  def test_running_load_should_monitor_new_watches
    code = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    Watch.any_instance.expects(:monitor)
    God.running_load(code, '/foo/bar.god')
  end

  def test_running_load_should_not_monitor_new_watches_with_autostart_false
    code = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
        w.autostart = false
      end
    EOF

    Watch.any_instance.expects(:monitor).never
    God.running_load(code, '/foo/bar.god')
  end

  def test_running_load_should_return_array_of_affected_watches
    code = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    w = nil
    w, e = *God.running_load(code, '/foo/bar.god')
    assert_equal 1, w.size
    assert_equal 'foo', w.first
  end

  def test_running_load_should_clear_pending_watches
    code = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    God.running_load(code, '/foo/bar.god')
    assert_equal 0, God.pending_watches.size
  end

  def test_running_load_with_stop
    code_one = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    code_two = <<-EOF
      God.watch do |w|
        w.name = 'bar'
        w.start = 'go'
      end
    EOF

    a, e, r = *God.running_load(code_one, '/foo/one.god', 'stop')

    assert_equal 1, a.size
    assert_equal 0, r.size

    a, e, r = *God.running_load(code_two, '/foo/two.god', 'stop')

    assert_equal 1, a.size
    assert_equal 1, r.size
  end

  def test_running_load_with_remove
    code_one = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    code_two = <<-EOF
      God.watch do |w|
        w.name = 'bar'
        w.start = 'go'
      end
    EOF

    a, e, r = *God.running_load(code_one, '/foo/one.god', 'remove')

    assert_equal 1, a.size
    assert_equal 0, r.size

    a, e, r = *God.running_load(code_two, '/foo/two.god', 'remove')

    assert_equal 1, a.size
    assert_equal 1, r.size
  end

  def test_running_load_with_leave
    code_one = <<-EOF
      God.watch do |w|
        w.name = 'foo'
        w.start = 'go'
      end
    EOF

    code_two = <<-EOF
      God.watch do |w|
        w.name = 'bar'
        w.start = 'go'
      end
    EOF

    a, e, r = *God.running_load(code_one, '/foo/one.god', 'leave')

    assert_equal 1, a.size
    assert_equal 0, r.size

    a, e, r = *God.running_load(code_two, '/foo/two.god', 'leave')

    assert_equal 1, a.size
    assert_equal 0, r.size
  end

  # load

  def test_load_should_collect_and_load_globbed_path
    Dir.expects(:[]).with('/path/to/*.thing').returns(['a', 'b'])
    Kernel.expects(:load).with('a').once
    Kernel.expects(:load).with('b').once
    God.load('/path/to/*.thing')
  end

  # start

  def test_start_should_kick_off_a_server_instance
    God::Socket.expects(:new).returns(true)
    God.start
  end

  def test_start_should_begin_monitoring_autostart_watches
    God.watch do |w|
      w.name = 'foo'
      w.start = 'go'
    end

    Watch.any_instance.expects(:monitor).once
    God.start
  end

  def test_start_should_not_begin_monitoring_non_autostart_watches
    God.watch do |w|
      w.name = 'foo'
      w.start = 'go'
      w.autostart = false
    end

    Watch.any_instance.expects(:monitor).never
    God.start
  end

  def test_start_should_get_and_join_timer
    God.watch { |w| w.name = 'foo'; w.start = 'bar' }
    God.start
  end

  # at_exit

  def test_at_exit_should_call_start
    God.expects(:start).once
    God.at_exit
  end

  # pattern_match

  def test_pattern_match
    list = %w{ mongrel-3000 mongrel-3001 fuzed22 fuzed fuzed2 apache mysql}

    assert_equal %w{ mongrel-3000 }, God.pattern_match('m3000', list)
    assert_equal %w{ mongrel-3001 }, God.pattern_match('m31', list)
    assert_equal %w{ fuzed fuzed2 fuzed22}, God.pattern_match('fu', list)
    assert_equal %w{ mysql }, God.pattern_match('sql', list)
  end
end


# class TestGodOther < Test::Unit::TestCase
#   def setup
#     God::Socket.stubs(:new).returns(true)
#     God.internal_init
#     God.reset
#   end
#
#   def teardown
#     God.main && God.main.kill
#   end
#
#   # setup
#
#   def test_setup_should_create_pid_file_directory_if_it_doesnt_exist
#     God.expects(:test).returns(false)
#     FileUtils.expects(:mkdir_p).with(God.pid_file_directory)
#     God.setup
#   end
#
#   def test_setup_should_raise_if_no_permissions_to_create_pid_file_directory
#     God.expects(:test).returns(false)
#     FileUtils.expects(:mkdir_p).raises(Errno::EACCES)
#
#     assert_abort do
#       God.setup
#     end
#   end
#
#   # validate
#
#   def test_validate_should_abort_if_pid_file_directory_is_unwriteable
#     God.expects(:test).returns(false)
#     assert_abort do
#       God.validater
#     end
#   end
#
#   def test_validate_should_not_abort_if_pid_file_directory_is_writeable
#     God.expects(:test).returns(true)
#     assert_nothing_raised do
#       God.validater
#     end
#   end
# end
