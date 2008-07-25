require File.dirname(__FILE__) + '/helper'
require 'tinder'

class TestCampfire < Test::Unit::TestCase
  def test_exists
    God::Contacts::Campfire
  end
  
  # should notify
  def test_campfire_delivery_method_for_notify
    assert_nothing_raised do
      
      room = mock()
      room.expects(:speak).returns(nil)
      
      g = God::Contacts::Campfire.new
      God::Contacts::Campfire.format.expects(:call).with(:a,:e)
      g.expects(:room).returns(room)
      g.notify(:a, :b, :c, :d, :e)
      assert_equal "notified campfire: ", g.info
    end
  end
  
  # should not establish a new connection because the older is alive
  def test_campfire_room_method
   assert_nothing_raised do
     room = mock()
     g = God::Contacts::Campfire.new
     g.instance_variable_set(:@room,room)
     assert_equal g.send(:room), room
   end
  end
  
  # should raise because the connections parameters have not been set
  def test_campfire_delivery_method_for_notify_without_campfire_params
    LOG.expects(:log).times(3) # 3 calls: 2 debug (credentials, backtrace) + 1 info (failed message)
    g = God::Contacts::Campfire.new
    g.notify(:a, :b, :c, :d, :e)
  end
  
end