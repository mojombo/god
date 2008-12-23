#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestJabber < Test::Unit::TestCase

  def setup
    God::Contacts::Jabber.settings = { 
      :jabber_id => 'test@example.com',
      :password => 'pass'
    }
    @jabber = God::Contacts::Jabber.new
    @jabber.jabber_id = 'recipient@example.com'
  end

  def test_notify
    assert_nothing_raised do
      God::Contacts::Jabber.any_instance.expects(:connect!).once.returns(nil)
      God::Contacts::Jabber.any_instance.expects(:send!).once.returns(nil)
      @jabber.notify(:a, :b, :c, :d, :e)
      assert_equal "sent jabber message to recipient@example.com", @jabber.info
    end
  end
  
  # def test_live_notify
  #   God::Contacts::Jabber.settings = { 
  #     :jabber_id => 'real_user@example.com',
  #     :password => 'pass'
  #   }
  #   recipient = "real_recipient@example.com"
  #   
  #   jabber = God::Contacts::Jabber.new
  #   jabber.jabber_id = recipient
  #   jabber.notify("Hello", Time.now, "Test", "Test", "localhost")
  #   assert_equal "sent jabber message to #{recipient}", jabber.info
  # end
end