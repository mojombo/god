require 'monitor'

# Taken from http://redmine.ruby-lang.org/repositories/entry/ruby-19/lib/monitor.rb

module MonitorMixin
  class ConditionVariable
    def wait(timeout = nil)
      @monitor.__send__(:mon_check_owner)
      count = @monitor.__send__(:mon_exit_for_cond)
      begin
        @cond.wait(@monitor.instance_variable_get("@mon_mutex"), timeout)
        return true
      ensure
        @monitor.__send__(:mon_enter_for_cond, count)
      end
    end
  end
end

# Taken from http://redmine.ruby-lang.org/repositories/entry/ruby-19/lib/thread.rb

class ConditionVariable
  def wait(mutex, timeout=nil)
    begin
      # TODO: mutex should not be used
      @waiters_mutex.synchronize do
        @waiters.push(Thread.current)
      end
      mutex.sleep timeout
    end
    self
  end
end
