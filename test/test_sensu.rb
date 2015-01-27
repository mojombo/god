#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestSensu < Test::Unit::TestCase
  def test_sensu_notify
    sensu = God::Contacts::Sensu.new
    sensu.check_name = "TestSensuContact"

    sensu.notify("Test", Time.now, "Test", "Test", "")
    assert_equal "sent sensu #{sensu.check_name} notification with status code #{sensu.status_code}", "sent sensu #{sensu.check_name} notification with status code #{sensu.status_code}"
  end
end
