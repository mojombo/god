require File.dirname(__FILE__) + '/helper'

class TestWebhook < Minitest::Test
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

  def test_notify_with_process_data_callback
    data_to_send = {:processed => true}
    data_callback = proc do |message, time, priority, category, host|
      data_to_send
    end

    @webhook.url = 'http://example.com/switch'
    @webhook.format = :json
    @webhook.process_data = data_callback
    Net::HTTP.any_instance.expects(:request).with {|req| req.body == data_to_send.to_json }.returns(Net::HTTPSuccess.new('a', 'b', 'c'))

    @webhook.notify('msg', Time.now, 'prio', 'cat', 'host')
  end
end
