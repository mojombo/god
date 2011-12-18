require File.dirname(__FILE__) + '/helper'

class TestCampfire < Test::Unit::TestCase
  def setup
    @campfire = God::Contacts::Campfire.new
  end

  def test_exists
    God::Contacts::Campfire
  end

  def test_notify
    @campfire.subdomain = 'github'
    @campfire.token = 'abc'
    @campfire.room = 'danger'

    time = Time.now
    body = "[#{time.strftime('%H:%M:%S')}] host - msg"
    Marshmallow::Connection.any_instance.expects(:speak).with('danger', body)
    @campfire.notify('msg', time, 'prio', 'cat', 'host')
  end
end
