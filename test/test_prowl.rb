#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestProwl < Test::Unit::TestCase
  def test_live_notify
    prowl = God::Contacts::Prowl.new
    prowl.name = "Prowly"
    prowl.apikey = 'put_your_apikey_here'

    Prowly.expects(:notify).returns(mock(:succeeded? => true))

    prowl.notify("Test", Time.now, "Test", "Test", "")
    assert_equal "sent prowl notification to #{prowl.name}", prowl.info
  end
end
