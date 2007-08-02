require File.dirname(__FILE__) + '/helper'

class TestSystemProcess < Test::Unit::TestCase
  def setup
    pid = Process.pid
    @process = System::Process.new(pid)
  end
  
  def test_exists_should_return_true_for_running_process
    assert_equal true, @process.exists?
  end
  
  def test_exists_should_return_false_for_non_existant_process
    assert_equal false, System::Process.new(5555555555).exists?
  end
  
  def test_memory
    assert_kind_of Integer, @process.memory
    assert @process.memory > 0
  end
  
  def test_percent_memory
    assert_kind_of Float, @process.percent_memory
  end
  
  def test_percent_cpu
    assert_kind_of Float, @process.percent_cpu
  end
  
  def test_cpu_time
    assert_kind_of Integer, @process.cpu_time
  end
  
  def test_time_string_to_seconds
    assert_equal 0, @process.bypass.time_string_to_seconds('0:00:00')
    assert_equal 0, @process.bypass.time_string_to_seconds('0:00:55')
    assert_equal 27, @process.bypass.time_string_to_seconds('0:27:32')
    assert_equal 75, @process.bypass.time_string_to_seconds('1:15:13')
    assert_equal 735, @process.bypass.time_string_to_seconds('12:15:13')
  end
end

