require File.dirname(__FILE__) + '/helper'

class TestSugar < Test::Unit::TestCase
  def test_seconds
    assert_equal 1, 1.seconds
    assert_equal 1, 1.second
  end
  
  def test_minutes
    assert_equal 60, 1.minutes
    assert_equal 60, 1.minute
  end
  
  def test_hours
    assert_equal 3600, 1.hours
    assert_equal 3600, 1.hour
  end
  
  def test_days
    assert_equal 86400, 1.days
    assert_equal 86400, 1.day
  end
  
  def test_kilobytes
    assert_equal 1, 1.kilobytes
    assert_equal 1, 1.kilobyte
  end
  
  def test_megabytes
    assert_equal 1024, 1.megabytes
    assert_equal 1024, 1.megabyte
  end
  
  def test_gigabytes
    assert_equal 1024 ** 2, 1.gigabytes
    assert_equal 1024 ** 2, 1.gigabyte
  end
  
  def test_percent
    assert_equal 1, 1.percent
  end
end
