require File.dirname(__FILE__) + '/helper'

module God
  class Process
    # def fork
    #   raise "You forgot to stub fork"
    # end

    def exec(*args)
      raise "You forgot to stub exec"
    end
  end
end

class TestProcessChild < Test::Unit::TestCase
  def setup
    God.internal_init
    @p = God::Process.new
    @p.name = 'foo'
    @p.stubs(:test).returns true # so we don't try to mkdir_p
    Process.stubs(:detach) # because we stub fork

    ::Process::Sys.stubs(:setuid).returns(true)
    ::Process::Sys.stubs(:setgid).returns(true)
  end

  # valid?

  def test_valid_should_return_true_if_auto_daemonized_and_log
    @p.start = 'qux'
    @p.log = 'bar'

    assert @p.valid?
  end

  def test_valid_should_return_true_if_auto_daemonized_and_no_stop
    @p.start = 'qux'
    @p.log = 'bar'

    assert @p.valid?
  end

  def test_valid_should_return_true_if_uid_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.uid = 'root'

    assert @p.valid?
  end

  def test_valid_should_return_true_if_uid_does_not_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.uid = 'foobarbaz'

    assert !@p.valid?
  end

  def test_valid_should_return_true_if_gid_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.gid = 'wheel'

    assert @p.valid?
  end

  def test_valid_should_return_false_if_gid_does_not_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.gid = 'foobarbaz'

    assert !@p.valid?
  end

  def test_valid_should_return_true_if_dir_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.dir = '/tmp'

    assert @p.valid?
  end

  def test_valid_should_return_false_if_dir_does_not_exists
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.dir = '/tmp/doesnotexist'

    assert !@p.valid?
  end

  def test_valid_should_return_false_if_dir_is_not_a_dir
    @p.start = 'qux'
    @p.log = '/tmp/foo.log'
    @p.dir = '/etc/passwd'

    assert !@p.valid?
  end

  def test_valid_should_return_false_with_bogus_chroot
    @p.chroot = '/bogusroot'

    assert !@p.valid?
  end

  def test_valid_should_return_true_with_chroot_and_valid_log
    @p.start = 'qux'
    @p.chroot = '/tmp'
    @p.log = '/tmp/foo.log'

    File.expects(:exist?).with('/tmp').returns(true)
    File.expects(:exist?).with('/tmp/foo.log').returns(true)
    File.expects(:exist?).with('/tmp/dev/null').returns(true)

    assert @p.valid?
  end

  # call_action

  def test_call_action_should_write_pid
    # Only for start, restart
    [:start, :restart].each do |action|
      @p.stubs(:test).returns true
      IO.expects(:pipe).returns([StringIO.new('1234'), StringIO.new])
      @p.expects(:fork)
      Process.expects(:waitpid)
      File.expects(:open).with(@p.default_pid_file, 'w')
      @p.send("#{action}=", "run")
      @p.call_action(action)
    end
  end
end

###############################################################################
#
# Daemon
#
###############################################################################

class TestProcessDaemon < Test::Unit::TestCase
  def setup
    God.internal_init
    @p = God::Process.new
    @p.name = 'foo'
    @p.pid_file = 'blah.pid'
    @p.stubs(:test).returns true # so we don't try to mkdir_p
    Process.stubs(:detach) # because we stub fork
  end

  # alive?

  def test_alive_should_call_system_process_exists
    File.expects(:read).with('blah.pid').times(2).returns('1234')
    System::Process.any_instance.expects(:exists?).returns(false)
    assert !@p.alive?
  end

  def test_alive_should_return_false_if_no_such_file
    File.expects(:read).with('blah.pid').raises(Errno::ENOENT)
    assert !@p.alive?
  end

  # valid?

  def test_valid_should_return_false_if_no_start
    @p.name = 'foo'
    @p.stop = 'baz'
    assert !@p.valid?
  end

  # pid

  def test_pid_should_return_integer_for_valid_pid_files
    File.stubs(:read).returns("123")
    assert_equal 123, @p.pid
  end

  def test_pid_should_return_nil_for_missing_files
    @p.pid_file = ''
    assert_equal nil, @p.pid
  end

  def test_pid_should_return_nil_for_invalid_pid_files
    File.stubs(:read).returns("four score and seven years ago")
    assert_equal nil, @p.pid
  end

  def test_pid_should_retain_last_pid_value_if_pid_file_is_removed
    File.stubs(:read).returns("123")
    assert_equal 123, @p.pid

    File.stubs(:read).raises(Errno::ENOENT)
    assert_equal 123, @p.pid

    File.stubs(:read).returns("246")
    assert_equal 246, @p.pid
  end

  # default_pid_file

  def test_default_pid_file
    assert_equal File.join(God.pid_file_directory, 'foo.pid'), @p.default_pid_file
  end

  # unix socket

  def test_unix_socket_should_return_path_specified
    @p.unix_socket = '/path/to-socket'
    assert_equal '/path/to-socket', @p.unix_socket
  end

  # umask
  def test_umask_should_return_umask_specified
    @p.umask = 002
    assert_equal 002, @p.umask
  end

  # call_action
  # These actually excercise call_action in the back at this point - Kev

  def test_call_action_with_string_should_call_system
    @p.start = "do something"
    @p.expects(:fork)
    Process.expects(:waitpid2).returns([123, 0])
    @p.call_action(:start)
  end

  def test_call_action_with_lambda_should_call
    cmd = lambda { puts "Hi" }
    cmd.expects(:call)
    @p.start = cmd
    @p.call_action(:start)
  end

  def test_call_action_with_invalid_command_class_should_raise
    @p.start = 5
    @p.stop = 'baz'

    assert @p.valid?

    assert_raise NotImplementedError do
      @p.call_action(:start)
    end
  end

  # start!/stop!/restart!

  def test_start_stop_restart_bang
    [:start, :stop, :restart].each do |x|
      @p.expects(:call_action).with(x)
      @p.send("#{x}!")
    end
  end
end
