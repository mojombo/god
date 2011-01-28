require 'helper'

class TestCampfire < Test::Unit::TestCase

  def setup
    @campfire = God::Contacts::Campfire.new
  end

  test "exists" do
    God::Contacts::Campfire
  end

  test "notify" do
    @campfire.subdomain = 'github'
    @campfire.token = 'abc'
    @campfire.room = 'danger'

    time = Time.now
    body = "[#{time.strftime('%H:%M:%S')}] host - msg"
    Marshmallow::Connection.any_instance.expects(:speak).with('danger', body)
    @campfire.notify('msg', time, 'prio', 'cat', 'host')
  end

end