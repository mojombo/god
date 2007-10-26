require File.dirname(__FILE__) + '/helper'

class TestConditionsDiskUsage < Test::Unit::TestCase
  # valid?
  
  def test_valid_should_return_false_if_no_above_given
    c = Conditions::DiskUsage.new
    c.mount_point = '/'
    c.watch = stub(:name => 'foo')
    
    no_stdout do
      assert_equal false, c.valid?
    end
  end
  
  def test_valid_should_return_false_if_no_mount_point_given
    c = Conditions::DiskUsage.new
    c.above = 90
    c.watch = stub(:name => 'foo')
    
    no_stdout do
      assert_equal false, c.valid?
    end
  end
  
  def test_valid_should_return_true_if_required_options_all_set
    c = Conditions::DiskUsage.new
    c.above = 90
    c.mount_point = '/'
    c.watch = stub(:name => 'foo')
    
    assert_equal true, c.valid?
  end
  
  # test
  
  def test_test_should_return_true_if_above_limit
    c = Conditions::DiskUsage.new
    c.above = 90
    c.mount_point = '/'
    
    c.expects(:`).returns('91')
    
    assert_equal true, c.test
  end
  
  def test_test_should_return_false_if_below_limit
    c = Conditions::DiskUsage.new
    c.above = 90
    c.mount_point = '/'
    
    c.expects(:`).returns('90')
    
    assert_equal false, c.test
  end
end