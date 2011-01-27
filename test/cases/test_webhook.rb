require File.dirname(__FILE__) + '/helper'

class TestWebhook < Test::Unit::TestCase
  def setup
    @webhook = God::Contacts::Webhook.new
  end

  def test_notify
    @webhook.url = 'http://example.com/switch'
    Net::HTTP.any_instance.expects(:request).returns(Net::HTTPSuccess.new('a', 'b', 'c'))

    @webhook.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "sent webhook to http://example.com/switch", @webhook.info
  end
end
