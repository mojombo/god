require File.dirname(__FILE__) + '/helper'

class TestStatsd < Minitest::Test
  def setup
    @statsd = God::Contacts::Statsd.new
  end

  def test_exists
    God::Contacts::Statsd
  end

  def test_notify
    [
        'cpu out of bounds',
        'memory out of bounds',
        'process is flapping'
    ].each do |event_type|
      ::Statsd.any_instance.expects(:increment).with("god.#{event_type.gsub(/\s/, '_')}.127_0_0_1.myapp-thin-1234")
      @statsd.notify("myapp-thin-1234 [trigger] #{event_type}", Time.now, 'some priority', 'and some category', '127.0.0.1')
    end
  end
end
