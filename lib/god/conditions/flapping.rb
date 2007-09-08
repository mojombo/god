module God
  module Conditions
    
    class Flapping < TriggerCondition
      attr_accessor :times, :within, :from_state, :to_state, :retry_in, :retry_times, :retry_within
      
      def prepare
        @timeline = Timeline.new(self.times)
        @retry_timeline = Timeline.new(self.retry_times)
      end
      
      def valid?
        valid = true
        valid &= complain("You must specify the 'times' attribute for :flapping") if self.times.nil?
        valid &= complain("You must specify the 'within' attribute for :flapping") if self.within.nil?
        valid &= complain("You must specify either the 'from_state', 'to_state', or both attributes for :flapping") if self.from_state.nil? && self.to_state.nil?
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
              Syslog.debug(msg)
              LOG.log(self.watch, :info, msg)
            end
          else
            # try again later
            Thread.new do
              sleep 1
            
              # log
              msg = "#{self.watch.name} auto-reenable monitoring in #{self.retry_in} seconds"
              Syslog.debug(msg)
              LOG.log(self.watch, :info, msg)
            
              sleep self.retry_in
            
              # log
              msg = "#{self.watch.name} auto-reenabling monitoring"
              Syslog.debug(msg)
              LOG.log(self.watch, :info, msg)
            
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