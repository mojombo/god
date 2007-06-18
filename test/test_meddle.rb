require File.dirname(__FILE__) + '/helper'

class TestMeddle < Test::Unit::TestCase
  def setup
    Server.stubs(:new).returns(true)
    @meddle = Meddle.new
  end
  
  def test_should_initialize_watches_to_empty_array
    assert_equal [], @meddle.watches
  end
  
  def test_watches_should_get_stored
    watch = nil
    @meddle.watch { |w| watch = w }
    
    assert_equal 1, @meddle.watches.size
    assert_equal watch, @meddle.watches.first
  end

  def test_should_kick_off_a_server_instance
    Server.expects(:new).returns(true)
    Meddle.new
  end

  def test_should_take_an_options_hash
    Server.expects(:new)
    Meddle.new(:port => 5555)
  end
end
