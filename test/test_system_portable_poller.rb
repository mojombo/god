require File.dirname(__FILE__) + '/helper'

class TestSystemPortablePoller < Test::Unit::TestCase
  def setup
    pid = Process.pid
    @process = System::PortablePoller.new(pid)
  end
  
  def test_time_string_to_seconds
    assert_equal 0, @process.bypass.time_string_to_seconds('0:00:00')
    assert_equal 0, @process.bypass.time_string_to_seconds('0:00:55')
    assert_equal 27, @process.bypass.time_string_to_seconds('0:27:32')
    assert_equal 75, @process.bypass.time_string_to_seconds('1:15:13')
    assert_equal 735, @process.bypass.time_string_to_seconds('12:15:13')
  end
end

