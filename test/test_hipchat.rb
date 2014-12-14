require File.dirname(__FILE__) + '/helper'

class TestHipchat < Minitest::Test
  def setup
    @hipchat = God::Contacts::Hipchat.new
  end

  def test_exists
    God::Contacts::Hipchat
  end

  def test_notify
    @hipchat.token = 'ee64d6e2337310af'
    @hipchat.ssl = 'true'
    @hipchat.room = 'testroom'
    @hipchat.from = 'test'

    time = Time.now
    body = "[#{time.strftime('%H:%M:%S')}] host - msg"
    Marshmallow::Connection.any_instance.expects(:speak).with('testroom', body)
    @hipchat.notify('msg', time, 'prio', 'cat', 'host')
  end
end
