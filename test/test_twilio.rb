require File.dirname(__FILE__) + '/helper'

class TestTwilio < Test::Unit::TestCase
  def setup
    @twilio = God::Contacts::Twilio.new
  end

  def test_exists
    God::Contacts::Twilio
  end

  def test_notify
  	@twilio.account_sid = 'ACXXXXX'
  	@twilio.auth_token = 'YYYYYY'
  	@twilio.from_number = '1234567890'
    @twilio.to_number = '9876543210'
    time = Time.now
    Twilio.expects(:notify).returns(mock(:sid => 'ACXXXXX'))
    @twilio.notify('msg', time, 'prio', 'cat', 'host')
    assert_equal "sent txt message to 9876543210", @twilio.info
  end
end