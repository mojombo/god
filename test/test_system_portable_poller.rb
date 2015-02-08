require File.dirname(__FILE__) + '/helper'

class TestSystemPortablePoller < Minitest::Test
  def setup
    @process = System::PortablePoller.new(123)
  end

  def test_elapsed_time_for_a_process_that_has_been_alive_for_less_than_an_hour
    @process.expects(:`).returns("00:11\n")
    assert_equal 11, @process.elapsed_time
  end

  def test_elapsed_time_for_a_process_that_has_been_alive_for_more_than_an_hour_but_less_than_a_day
    @process.expects(:`).returns("03:00:01\n")
    assert_equal 10801, @process.elapsed_time
  end

  def test_elapsed_time_for_a_process_that_has_been_alive_for_more_than_a_day
    @process.expects(:`).returns("141-23:10:18\n")
    assert_equal 12265818, @process.elapsed_time
  end

  def test_elapsed_time_with_whitespace_before_time
    @process.expects(:`).returns(" 141-23:10:18\n")
    assert_equal 12265818, @process.elapsed_time
  end

end

