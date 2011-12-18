require File.dirname(__FILE__) + '/helper'

class TestLogger < Test::Unit::TestCase
  def setup
    @log = God::Logger.new(StringIO.new('/dev/null'))
  end

  # log

  def test_log_should_keep_logs_when_wanted
    @log.watch_log_since('foo', Time.now)
    @log.expects(:info).with("qux")

    @log.log(stub(:name => 'foo'), :info, "qux")

    assert_equal 1, @log.logs.size
    assert_instance_of Time, @log.logs['foo'][0][0]
    assert_match(/qux/, @log.logs['foo'][0][1])
  end

  def test_log_should_send_to_syslog
    SysLogger.expects(:log).with(:fatal, 'foo')
    @log.log(stub(:name => 'foo'), :fatal, "foo")
  end

  # watch_log_since

  def test_watch_log_since
    t1 = Time.now

    @log.watch_log_since('foo', t1)

    @log.log(stub(:name => 'foo'), :info, "one")
    @log.log(stub(:name => 'foo'), :info, "two")

    assert_match(/one.*two/m, @log.watch_log_since('foo', t1))

    t2 = Time.now

    @log.log(stub(:name => 'foo'), :info, "three")

    out = @log.watch_log_since('foo', t2)

    assert_no_match(/one/, out)
    assert_no_match(/two/, out)
    assert_match(/three/, out)
  end

  # regular methods

  def test_fatal
    @log.fatal('foo')
    assert_equal 0, @log.logs.size
  end
end
