#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestAirbrake < Minitest::Test
  def test_notify
    airbrake = God::Contacts::Airbrake.new
    airbrake.apikey = "put_your_apikey_here"
    airbrake.name = "Airbrake"

    Airbrake.expects(:notify).returns "123"

    airbrake.notify("Test message for airbrake", Time.now, "airbrake priority", "airbrake category", "")
  end
end
