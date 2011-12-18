module God
  module Behaviors

    class NotifyWhenFlapping < Behavior
      attr_accessor :failures # number of failures
      attr_accessor :seconds  # number of seconds
      attr_accessor :notifier # class to notify with

      def initialize
        super
        @startup_times = []
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'failures' must be specified", self) unless self.failures
        valid &= complain("Attribute 'seconds' must be specified", self) unless self.seconds
        valid &= complain("Attribute 'notifier' must be specified", self) unless self.notifier

        # Must take one arg or variable args
        unless self.notifier.respond_to?(:notify) and [1,-1].include?(self.notifier.method(:notify).arity)
          valid &= complain("The 'notifier' must have a method 'notify' which takes 1 or variable args", self)
        end

        valid
      end

      def before_start
        now = Time.now.to_i
        @startup_times << now
        check_for_flapping(now)
      end

      def before_restart
        now = Time.now.to_i
        @startup_times << now
        check_for_flapping(now)
      end

      private

        def check_for_flapping(now)
          @startup_times.select! {|time| time >= now - self.seconds }
          if @startup_times.length >= self.failures
            self.notifier.notify("#{self.watch.name} has called start/restart #{@startup_times.length} times in #{self.seconds} seconds")
          end
        end
    end

  end
end
