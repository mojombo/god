require File.dirname(__FILE__) + '/helper'

class TestTwilio < Test::Unit::TestCase
  def setup
    @twilio = God::Contacts::Twilio.new
  end

  def test_exists
    God::Contacts::Twilio
  end

  def test_notify
  	@twilio.account_sid = 'AC6d969d749c7e4e0bb5eb8968b85fa759'
  	@twilio.auth_token = '1c43e9e653a181a3180083297ca6cf81'
  	@twilio.from_number = '4069604079'
    @twilio.to_number = '9406004450'
    time = Time.now
    @twilio.notify('msg', time, 'prio', 'cat', 'host')
    assert_equal "sent txt message to 9406004450", @twilio.info
  end
end
