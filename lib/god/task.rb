module God
  
  class Task
    attr_accessor :name, :interval, :group, :valid_states, :initial_state, :driver
    
    attr_writer   :autostart
    def autostart?; @autostart; end
    
    # api
    attr_accessor :state, :behaviors, :metrics, :directory
    
    def initialize
      @autostart ||= true
      
      # initial state is unmonitored
      self.state = :unmonitored
      
      # the list of behaviors
      self.behaviors = []
      
      # the list of conditions for each action
      self.metrics = {nil => [], :unmonitored => [], :stop => []}
      
      # the condition -> metric lookup
      self.directory = {}
      
      # driver
      self.driver = Driver.new(self)
    end
    
    def prepare
      self.valid_states.each do |state|
        self.metrics[state] ||= []
      end
    end
    
    def valid?
      valid = true
      
      # a name must be specified
      if self.name.nil?
        valid = false
        applog(self, :error, "No name was specified")
      end
      
      # valid_states must be specified
      if self.valid_states.nil?
        valid = false
        applog(self, :error, "No valid_states array was specified")
      end
      
      # valid_states must be specified
      if self.initial_state.nil?
        valid = false
        applog(self, :error, "No initial_state was specified")
      end
      
      valid
    end
    
    ###########################################################################
    #
    # Advanced mode
    #
    ###########################################################################
    
    def canonical_hash_form(to)
      to.instance_of?(Symbol) ? {true => to} : to
    end
    
    # Define a transition handler which consists of a set of conditions
    def transition(start_states, end_states)
      # convert end_states into canonical hash form
      canonical_end_states = canonical_hash_form(end_states)
      
      Array(start_states).each do |start_state|
        # validate start state
        unless self.valid_states.include?(start_state)
          abort "Invalid state :#{start_state}. Must be one of the symbols #{self.valid_states.map{|x| ":#{x}"}.join(', ')}"
        end
        
        # create a new metric to hold the watch, end states, and conditions
        m = Metric.new(self, canonical_end_states)
        
        if block_given?
          # let the config file define some conditions on the metric
          yield(m)
        else
          # add an :always condition if no block
          m.condition(:always) do |c|
            c.what = true
          end
        end
        
        # populate the condition -> metric directory
        m.conditions.each do |c|
          self.directory[c] = m
        end
        
        # record the metric
        self.metrics[start_state] ||= []
        self.metrics[start_state] << m
      end
    end
    
    def lifecycle
      # create a new metric to hold the watch and conditions
      m = Metric.new(self)
      
      # let the config file define some conditions on the metric
      yield(m)
      
      # populate the condition -> metric directory
      m.conditions.each do |c|
        self.directory[c] = m
      end
      
      # record the metric
      self.metrics[nil] << m
    end
    
    ###########################################################################
    #
    # Lifecycle
    #
    ###########################################################################
        
    # Enable monitoring
    #
    # Returns nothing
    def monitor
      self.move(self.initial_state)
    end
    
    # Disable monitoring
    #
    # Returns nothing
    def unmonitor
      self.move(:unmonitored)
    end
    
    # Move to the givent state
    #   +to_state+ is the Symbol representing the state to move to
    #
    # Returns Task (self)
    def move(to_state)
      if Thread.current != self.driver.thread
        # called from outside Driver
        
        # send an async message to Driver
        self.driver.message(:move, [to_state])
      else
        # called from within Driver
        
        # record original info
        orig_to_state = to_state
        from_state = self.state
        
        # log
        msg = "#{self.name} move '#{from_state}' to '#{to_state}'"
        applog(self, :info, msg)
        
        # cleanup from current state
        self.driver.clear_events
        self.metrics[from_state].each { |m| m.disable }
        if to_state == :unmonitored
          self.metrics[nil].each { |m| m.disable }
        end
        
        # perform action
        self.action(to_state)
        
        # enable simple mode
        if [:start, :restart].include?(to_state) && self.metrics[to_state].empty?
          to_state = :up
        end
        
        # move to new state
        self.metrics[to_state].each { |m| m.enable }
        
        # if no from state, enable lifecycle metric
        if from_state == :unmonitored
          self.metrics[nil].each { |m| m.enable }
        end
        
        # set state
        self.state = to_state
        
        # broadcast to interested TriggerConditions
        Trigger.broadcast(self, :state_change, [from_state, orig_to_state])
        
        # log
        msg = "#{self.name} moved '#{from_state}' to '#{to_state}'"
        applog(self, :info, msg)
      end
      
      self
    end
    
    # Notify the Driver that an EventCondition has triggered
    #
    # Returns nothing
    def trigger(condition)
      self.driver.message(:handle_event, [condition])
    end
    
    def signal(sig)
      # noop
    end
    
    ###########################################################################
    #
    # Actions
    #
    ###########################################################################
    
    def method_missing(sym, *args)
      unless (sym.to_s =~ /=$/)
        super
      end
      
      base = sym.to_s.chop.intern
      
      unless self.valid_states.include?(base)
        super
      end
      
      self.class.send(:attr_accessor, base)
      self.send(sym, *args)
    end
    
    # Perform the given action
    #   +a+ is the action Symbol
    #   +c+ is the Condition
    #
    # Returns Task (self)
    def action(a, c = nil)
      if Thread.current != self.driver.thread
        # called from outside Driver
        
        # send an async message to Driver
        self.driver.message(:action, [a, c])
      else
        # called from within Driver
        
        if self.respond_to?(a)
          command = self.send(a)
          
          case command
            when String
              msg = "#{self.name} #{a}: #{command}"
              applog(self, :info, msg)
              
              system(command)
            when Proc
              msg = "#{self.name} #{a}: lambda"
              applog(self, :info, msg)
              
              command.call
            else
              raise NotImplementedError
          end
        end
      end
    end
    
    ###########################################################################
    #
    # Events
    #
    ###########################################################################
    
    def attach(condition)
      case condition
        when PollCondition
          self.driver.schedule(condition, 0)
        when EventCondition, TriggerCondition
          condition.register
      end
    end
    
    def detach(condition)
      case condition
        when PollCondition
          condition.reset
        when EventCondition, TriggerCondition
          condition.deregister
      end
    end
    
    ###########################################################################
    #
    # Registration
    #
    ###########################################################################
    
    def register!
      # override if necessary
    end
    
    def unregister!
      driver.shutdown
    end
    
    ###########################################################################
    #
    # Handlers
    #
    ###########################################################################
    
    # Evaluate and handle the given poll condition. Handles logging
    # notifications, and moving to the new state if necessary
    #   +condition+ is the Condition to handle
    #
    # Returns nothing
    def handle_poll(condition)
      # lookup metric
      metric = self.directory[condition]
      
      # run the test
      begin
        result = condition.test
      rescue Object => e
        cname = condition.class.to_s.split('::').last
        message = format("Unhandled exception in %s condition - (%s): %s\n%s",
                         cname, e.class, e.message, e.backtrace.join("\n"))
        applog(self, :error, message)
        result = false
      end
      
      # log
      messages = self.log_line(self, metric, condition, result)
      
      # notify
      if result && condition.notify
        self.notify(condition, messages.last)
      end
      
      # after-condition
      condition.after
      
      # get the destination
      dest = 
      if result && condition.transition
        # condition override
        condition.transition
      else
        # regular
        metric.destination && metric.destination[result]
      end
      
      # transition or reschedule
      if dest
        # transition
        begin
          self.move(dest)
        rescue EventRegistrationFailedError
          msg = self.name + ' Event registration failed, moving back to previous state'
          applog(self, :info, msg)
          
          dest = self.state
          retry
        end
      else
        # reschedule
        self.driver.schedule(condition)
      end
    end
    
    # Asynchronously evaluate and handle the given event condition. Handles logging
    # notifications, and moving to the new state if necessary
    #   +condition+ is the Condition to handle
    #
    # Returns nothing
    def handle_event(condition)
      # lookup metric
      metric = self.directory[condition]
      
      # log
      messages = self.log_line(self, metric, condition, true)
      
      # notify
      if condition.notify
        self.notify(condition, messages.last)
      end
      
      # get the destination
      dest = 
      if condition.transition
        # condition override
        condition.transition
      else
        # regular
        metric.destination && metric.destination[true]
      end
      
      if dest
        self.move(dest)
      end
    end
    
    # Determine whether a trigger happened
    #   +metric+ is the Metric
    #   +result+ is the result from the condition's test
    #
    # Returns Boolean
    def trigger?(metric, result)
      metric.destination && metric.destination[result]
    end
    
    # Log info about the condition and return the list of messages logged
    #   +watch+ is the Watch
    #   +metric+ is the Metric
    #   +condition+ is the Condition
    #   +result+ is the Boolean result of the condition test evaluation
    #
    # Returns String[]
    def log_line(watch, metric, condition, result)
      status = 
      if self.trigger?(metric, result)
        "[trigger]"
      else
        "[ok]"
      end
      
      messages = []
      
      # log info if available
      if condition.info
        Array(condition.info).each do |condition_info|
          messages << "#{watch.name} #{status} #{condition_info} (#{condition.base_name})"
          applog(watch, :info, messages.last)
        end
      else
        messages << "#{watch.name} #{status} (#{condition.base_name})"
        applog(watch, :info, messages.last)
      end
      
      # log
      debug_message = watch.name + ' ' + condition.base_name + " [#{result}] " + self.dest_desc(metric, condition)
      applog(watch, :debug, debug_message)
      
      messages
    end
    
    # Format the destination specification for use in debug logging
    #   +metric+ is the Metric
    #   +condition+ is the Condition
    #
    # Returns String
    def dest_desc(metric, condition)
      if condition.transition
        {true => condition.transition}.inspect
      else
        if metric.destination
          metric.destination.inspect
        else
          'none'
        end
      end
    end
    
    # Notify all recipeients of the given condition with the specified message
    #   +condition+ is the Condition
    #   +message+ is the String message to send
    #
    # Returns nothing
    def notify(condition, message)
      spec = Contact.normalize(condition.notify)
      unmatched = []
      
      # resolve contacts
      resolved_contacts =
      spec[:contacts].inject([]) do |acc, contact_name_or_group|
        cons = Array(God.contacts[contact_name_or_group] || God.contact_groups[contact_name_or_group])
        unmatched << contact_name_or_group if cons.empty?
        acc += cons
        acc
      end
      
      # warn about unmatched contacts
      unless unmatched.empty?
        msg = "#{condition.watch.name} no matching contacts for '#{unmatched.join(", ")}'"
        applog(condition.watch, :warn, msg)
      end
      
      # notify each contact
      resolved_contacts.each do |c|
        host = `hostname`.chomp rescue 'none'
        begin
          c.notify(message, Time.now, spec[:priority], spec[:category], host)
          msg = "#{condition.watch.name} #{c.info ? c.info : "notification sent for contact: #{c.name}"} (#{c.base_name})"
          applog(condition.watch, :info, msg % [])
        rescue Exception => e
          applog(condition.watch, :error, "#{e.message} #{e.backtrace}")
          msg = "#{condition.watch.name} Failed to deliver notification for contact: #{c.name} (#{c.base_name})"
          applog(condition.watch, :error, msg % [])
        end
      end
    end
  end
  
end
