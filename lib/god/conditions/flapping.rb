module God
  module Conditions

    # Condition Symbol :flapping
    # Type: Trigger
    #
    # Trigger when a Task transitions to or from a state or states a given number
    # of times within a given period.
    #
    # Paramaters
    #   Required
    #     +times+ is the number of times that the Task must transition before
    #             triggering.
    #     +within+ is the number of seconds within which the Task must transition
    #              the specified number of times before triggering. You may use
    #              the sugar methods #seconds, #minutes, #hours, #days to clarify
    #              your code (see examples).
    #     --one or both of--
    #     +from_state+ is the state (as a Symbol) from which the transition must occur.
    #     +to_state is the state (as a Symbol) to which the transition must occur.
    #
    #   Optional:
    #     +retry_in+ is the number of seconds after which to re-monitor the Task after
    #                it has been disabled by the condition.
    #     +retry_times+ is the number of times after which to permanently unmonitor
    #                   the Task.
    #     +retry_within+ is the number of seconds within which
    #
    # Examples
    #
    # Trigger if
    class Flapping < TriggerCondition
      attr_accessor :times,
                    :within,
                    :from_state,
                    :to_state,
                    :retry_in,
                    :retry_times,
                    :retry_within

      def initialize
        self.info = "process is flapping"
      end

      def prepare
        @timeline = Timeline.new(self.times)
        @retry_timeline = Timeline.new(self.retry_times)
      end

      def valid?
        valid = true
        valid &= complain("Attribute 'times' must be specified", self) if self.times.nil?
        valid &= complain("Attribute 'within' must be specified", self) if self.within.nil?
        valid &= complain("Attributes 'from_state', 'to_state', or both must be specified", self) if self.from_state.nil? && self.to_state.nil?
        valid
      end

      def process(event, payload)
        begin
          if event == :state_change
            event_from_state, event_to_state = *payload

            from_state_match = !self.from_state || self.from_state && Array(self.from_state).include?(event_from_state)
            to_state_match = !self.to_state || self.to_state && Array(self.to_state).include?(event_to_state)

            if from_state_match && to_state_match
              @timeline << Time.now

              concensus = (@timeline.size == self.times)
              duration = (@timeline.last - @timeline.first) < self.within

              if concensus && duration
                @timeline.clear
                trigger
                retry_mechanism
              end
            end
          end
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      private

      def retry_mechanism
        if self.retry_in
          @retry_timeline << Time.now

          concensus = (@retry_timeline.size == self.retry_times)
          duration = (@retry_timeline.last - @retry_timeline.first) < self.retry_within

          if concensus && duration
            # give up
            Thread.new do
              sleep 1

              # log
              msg = "#{self.watch.name} giving up"
              applog(self.watch, :info, msg)
            end
          else
            # try again later
            Thread.new do
              sleep 1

              # log
              msg = "#{self.watch.name} auto-reenable monitoring in #{self.retry_in} seconds"
              applog(self.watch, :info, msg)

              sleep self.retry_in

              # log
              msg = "#{self.watch.name} auto-reenabling monitoring"
              applog(self.watch, :info, msg)

              if self.watch.state == :unmonitored
                self.watch.monitor
              end
            end
          end
        end
      end
    end

  end
end
