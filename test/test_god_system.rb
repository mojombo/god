require File.dirname(__FILE__) + '/helper'

class TestGodSystem < MiniTest::Test
  def assert_watch_running(watch_name)
    assert_equal true, God.watches[watch_name].alive?
  end

  def with_god_cleanup
    old_terminate = God.method(:terminate)
    # necessary cuz actual god terminate will do exit(0) will stops tests
    God.class_eval do
      def self.terminate
        FileUtils.rm_f(self.pid) if self.pid
        self.server.stop if self.server
      end
    end
    begin
      yield
    ensure
      God.stop_all
      God.terminate # use our monkeypatched terminate
      God.watches.each do |name, w|
        w.stop_signal = 'KILL'
        w.action(:stop)
      end
      God.inited = false
      God.terminate_timeout = ::God::TERMINATE_TIMEOUT_DEFAULT
      God.internal_init # reset config, set running to false, etc.
      # set termiante back to old method, for other tests
      God.define_singleton_method(:terminate, old_terminate)
    end
  end

  def test_start_running
    with_god_cleanup do
      God.start
      assert_equal(God.running, true)
    end
  end

  def test_add_watch
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'add_watch'
        w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
      end
      assert God.watches['add_watch'] != nil
    end
  end

  def test_start_watch
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'start_watch'
        w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
      end
      God.watches['start_watch'].action(:start)
      sleep 2
      assert_equal true, God.watches['start_watch'].alive?
    end
  end

  def test_start_watch
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'start_watch'
        w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
      end
      God.watches['start_watch'].action(:start)
      sleep 2
      assert_equal true, God.watches['start_watch'].alive?
    end
  end

  def test_stop_all_with_one
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'start_watch'
        w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
      end
      God.watches['start_watch'].action(:start)
      sleep 2
      assert_equal true, God.watches['start_watch'].alive?
      God.stop_all
      assert_equal false, God.watches.any? { |name, w| w.alive? }
    end
  end

  # default 10s timeout will expire before SIGKILL sent
  def test_stop_all_with_non_killing_signal_long_timeout
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'long_timeout'
        w.stop_signal = 'USR1'
        w.stop_timeout = ::God::STOP_TIMEOUT_DEFAULT + 1
        w.start = File.join(GOD_ROOT, *%w[test configs usr1_trapper.rb])
      end
      God.watches['long_timeout'].action(:start)
      sleep 2
      assert_equal true, God.watches['long_timeout'].alive?
      God.stop_all
      assert_watch_running('long_timeout')
    end
  end

  # use short timeout to send SIGKILL before 10s timeout
  def test_stop_all_with_non_killing_signal_short_timeout
    with_god_cleanup do
      God.start
      God.watch do |w|
        w.name = 'short_timeout'
        w.stop_signal = 'USR1'
        w.stop_timeout = ::God::STOP_TIMEOUT_DEFAULT - 1
        w.start = File.join(GOD_ROOT, *%w[test configs usr1_trapper.rb])
      end
      God.watches['short_timeout'].action(:start)
      sleep 2
      assert_equal true, God.watches['short_timeout'].alive?
      God.stop_all
      assert_equal false, God.watches.any? { |name, w| w.alive? }
    end
  end

  # should be able to stop many simple watches within default timeout
  def test_stop_all_with_many_watches
    with_god_cleanup do
      God.start
      20.times do |i|
        God.watch do |w|
          w.name = "many_watches_#{i}"
          w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
        end
        God.watches["many_watches_#{i}"].action(:start)
      end
      while true do
        all_running = God.watches.select{ |name, w| name =~ /many_watches_/ }.all?{ |name, w| w.alive? }
        size = God.watches.size
        break if all_running && size >= 20
        sleep 2
      end
      God.stop_all
      assert_equal false, God.watches.any? { |name, w| w.alive? }
    end
  end

  # should be able to stop many simple watches within short timeout
  def test_stop_all_with_many_watches_short_timeout
    with_god_cleanup do
      God.start
      God.terminate_timeout = 1
      100.times do |i|
        God.watch do |w|
          w.name = "tons_of_watches_#{i}"
          w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
          w.keepalive
        end
        God.watches["tons_of_watches_#{i}"].action(:start)
      end
      while true do
        all_running = God.watches.select{ |name, w| name =~ /tons_of_watches_/ }.all?{ |name, w| w.alive? }
        size = God.watches.size
        break if all_running && size >= 100
        sleep 2
      end
      God.stop_all
      assert_equal false, God.watches.any? { |name, w| w.alive? }
    end
  end

  def test_god_terminate_with_many_watches_short_timeout
    with_god_cleanup do
      God.start
      God.terminate_timeout = 1
      100.times do |i|
        God.watch do |w|
          w.name = "tons_of_watches_#{i}"
          w.start = File.join(GOD_ROOT, *%w[test configs complex simple_server.rb])
          w.keepalive
        end
        God.watches["tons_of_watches_#{i}"].action(:start)
      end
      while true do
        all_running = God.watches.select{ |name, w| name =~ /tons_of_watches_/ }.all?{ |name, w| w.alive? }
        size = God.watches.size
        break if all_running && size >= 100
        sleep 2
      end
      begin
        God::CLI::Command.new('terminate', {port: 17165}, [])
      rescue SystemExit
      ensure
        assert_equal false, God.watches.any? { |name, w| w.alive? }
      end
    end
  end
end
