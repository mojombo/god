#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestJabber < Test::Unit::TestCase

  def setup
    @jabber = God::Contacts::Jabber.new
  end

  def test_notify
    @jabber.host = 'talk.google.com'
    @jabber.from_jid = 'god@jabber.org'
    @jabber.password = 'secret'
    @jabber.to_jid = 'dev@jabber.org'

    time = Time.now
    body = God::Contacts::Jabber.format.call('msg', time, 'prio', 'cat', 'host')

    assert_equal "Message: msg\nHost: host\nPriority: prio\nCategory: cat\n", body

    Jabber::Client.any_instance.expects(:connect).with('talk.google.com', 5222)
    Jabber::Client.any_instance.expects(:auth).with('secret')
    Jabber::Client.any_instance.expects(:send)
    Jabber::Client.any_instance.expects(:close)

    @jabber.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "sent jabber message to dev@jabber.org", @jabber.info
  end
end
