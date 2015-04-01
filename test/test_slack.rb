require File.dirname(__FILE__) + '/helper'

class TestSlack < Minitest::Test
  def setup
    @slack = God::Contacts::Slack.new

    # new slack webhook url contains three random 'tokens' with length of 9, 9 and 24 characters
    @slack.url = "https://hooks.slack.com/services/ABCABCABC/DEFDEFDEF/ABCDEFABCDEFABCDEFABCDEF"

    @sample_data = {
      :message => "a sample message",
      :time => "2038-01-01 00:00:00",
      :priority => "High",
      :category => "Test",
      :host => "example.com"
    }
  end

  def test_api_url
    assert_equal @slack.url, @slack.api_url.to_s
  end

  def test_notify
    Net::HTTP.any_instance.expects(:request).returns(Net::HTTPSuccess.new('a', 'b', 'c'))

    @slack.channel = "#ops"

    @slack.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "successfully notified slack on channel #ops", @slack.info
  end

  def test_default_channel
    Net::HTTP.any_instance.expects(:request).returns(Net::HTTPSuccess.new('a', 'b', 'c'))

    @slack.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "successfully notified slack on channel #general", @slack.info
  end

  def test_default_formatting
    text = @slack.text(@sample_data)
    assert_equal "High alert on example.com: a sample message (Test, 2038-01-01 00:00:00)", text
  end

  def test_custom_formatting
    @slack.format = "%{host}: %{message}"
    text = @slack.text(@sample_data)
    assert_equal "example.com: a sample message", text
  end

  def test_notify_channel
    @slack.notify_channel = true
    @slack.format = ""
    text = @slack.text(@sample_data)
    assert_equal "<!channel> ", text
  end
end

