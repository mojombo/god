require File.dirname(__FILE__) + '/helper'

class TestHipchat < Test::Unit::TestCase
  def setup
    @hipchat = God::Contacts::Hipchat.new
  end

  def test_exists
    God::Contacts::Hipchat
  end

  def test_notify
    @hipchat.token = '808da95553dfe06f413b12ff1d5772'
    @hipchat.ssl = 'true'
    @hipchat.room = 'philtest'

    time = Time.now
    body = "[#{time.strftime('%H:%M:%S')}] host - msg"
    Marshmallow::Connection.any_instance.expects(:speak).with('philtest', body)
    @hipchat.notify('msg', time, 'prio', 'cat', 'host')
  end
end
