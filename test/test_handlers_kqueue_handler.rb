require File.dirname(__FILE__) + '/helper'

if God::EventHandler.event_system == "kqueue"

  class TestHandlersKqueueHandler < Test::Unit::TestCase
    def test_register_process
      KQueueHandler.expects(:monitor_process).with(1234, 2147483648)
      KQueueHandler.register_process(1234, [:proc_exit])
    end

    def test_events_mask
      assert_equal 2147483648, KQueueHandler.events_mask([:proc_exit])
    end
  end

end
