require File.dirname(__FILE__) + '/helper'

class TestEmail < Test::Unit::TestCase
  def test_exists
    God::Contacts::Webhook
  end

  def test_notify
    assert_nothing_raised do
      g = God::Contacts::Webhook.new
      g.hook_url = 'http://test/switch'
      g.notify(:a, :b, :c, :d, :e)
      assert_equal "sent webhook to http://test/switch", g.info
    end
  end
  
end
