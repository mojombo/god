require File.dirname(__FILE__) + '/helper'

class TestLogger < Test::Unit::TestCase
  def setup
    @log = God::Logger.new
  end
  
  # log
  
  def test_log
    @log.expects(:info).with("qux")
    
    no_stdout do
      @log.log(stub(:name => 'foo'), :info, "qux")
    end
    
    assert_equal 1, @log.logs.size
    assert_instance_of Time, @log.logs['foo'][0][0]
    assert_match(/qux/, @log.logs['foo'][0][1])
  end
  
  # watch_log_since
  
  def test_watch_log_since
    t1 = Time.now
    
    no_stdout do
      @log.log(stub(:name => 'foo'), :info, "one")
      @log.log(stub(:name => 'foo'), :info, "two")
    end
    
    assert_match(/one.*two/m, @log.watch_log_since('foo', t1))
    
    t2 = Time.now
    
    no_stdout do
      @log.log(stub(:name => 'foo'), :info, "three")
    end
    
    out = @log.watch_log_since('foo', t2)
    
    assert_no_match(/one/, out)
    assert_no_match(/two/, out)
    assert_match(/three/, out)
  end
  
  # regular methods
  
  def test_fatal
    no_stdout do
      @log.fatal('foo')
    end
    assert_equal 0, @log.logs.size
  end
end