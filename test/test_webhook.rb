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

  def test_notify_with_url_containing_query_parameters
    @webhook.url = 'http://example.com/switch?api_key=123'
    Net::HTTP::Post.expects(:new).with('/switch?api_key=123')

    @webhook.notify('msg', Time.now, 'prio', 'cat', 'host')
  end
end
