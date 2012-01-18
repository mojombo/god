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
    @twilio.auth_token  = 'YYYYYY'
    @twilio.from_number = '1234567890'
    @twilio.to_number   = '9876543210'

    # law of demeter much?
    resource = mock.expects(:create).with :from => @twilio.from_number, :to => @twilio.to_number, :body => 'msg'
    client   = mock(:account => mock(:sms => mock(:messages => resource)))

    ::Twilio::REST::Client.expects(:new).with(@twilio.account_sid, @twilio.auth_token).returns client

    @twilio.notify('msg', Time.now, 'prio', 'cat', 'host')
  end
end
