require File.dirname(__FILE__) + '/helper'

class TestGod < Test::Unit::TestCase
  def setup
    Server.stubs(:new).returns(true)
    God.reset
  end
  
  def teardown
    Timer.get.timer.kill
  end
  
  def test_init_should_initialize_watches_to_empty_array
    God.init { }
    assert_equal Hash.new, God.watches
  end
  
  def test_watches_should_get_stored
    watch = nil
    God.watch { |w| watch = w }
    
    assert_equal 1, God.watches.size
    assert_equal watch, God.watches.values.first
    
    assert_equal 0, God.groups.size
  end
  
  def test_watches_should_register_processes
    assert_nil God.registry['foo']
    God.watch { |w| w.name = 'foo' }
    assert_kind_of God::Process, God.registry['foo']
  end
  
  def test_watches_should_get_stored_by_group
    God.watch do |w|
      w.name = 'foo'
      w.group = 'test'
    end
    
    assert_equal({'test' => ['foo']}, God.groups)
  end
  
  def test_multiple_watches_should_get_stored_by_group
    God.watch do |w|
      w.name = 'foo'
      w.group = 'test'
    end
    
    God.watch do |w|
      w.name = 'bar'
      w.group = 'test'
    end
    
    assert_equal({'test' => ['foo', 'bar']}, God.groups)
  end

  def test_should_kick_off_a_server_instance
    Server.expects(:new).returns(true)
    God.init
  end
  
  def test_should_allow_multiple_watches
    God.watch { |w| w.name = 'foo' }
    
    assert_nothing_raised do
      God.watch { |w| w.name = 'bar' }
    end
  end
  
  def test_should_disallow_duplicate_watch_names
    God.watch { |w| w.name = 'foo' }
    
    assert_raise AbortCalledError do
      God.watch { |w| w.name = 'foo' }
    end
  end
end
