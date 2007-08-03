require File.dirname(__FILE__) + '/helper'

class TestMeddle < Test::Unit::TestCase
  def setup
    Server.stubs(:new).returns(true)
    @meddle = Meddle.new
  end
  
  def test_should_initialize_watches_to_empty_array
    assert_equal Hash.new, @meddle.watches
  end
  
  def test_watches_should_get_stored
    watch = nil
    @meddle.watch { |w| watch = w }
    
    assert_equal 1, @meddle.watches.size
    assert_equal watch, @meddle.watches.values.first
  end

  def test_should_kick_off_a_server_instance
    Server.expects(:new).returns(true)
    Meddle.new
  end

  def test_should_take_an_options_hash
    Server.expects(:new)
    Meddle.new(:port => 5555)
  end
  
  def test_should_allow_multiple_watches
    @meddle.watch { |w| w.name = 'foo' }
    
    assert_nothing_raised do
      @meddle.watch { |w| w.name = 'bar' }
    end
  end
  
  def test_should_disallow_duplicate_watch_names
    @meddle.watch { |w| w.name = 'foo' }
    
    assert_raise AbortCalledError do
      @meddle.watch { |w| w.name = 'foo' }
    end
  end
end
