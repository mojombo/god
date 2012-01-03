module God
  # Metrics are responsible for holding watch conditions. An instance of
  # Metric is yielded to blocks in the start_if, restart_if, stop_if, and
  # transition methods.
  class Metric
    # The Watch.
    attr_accessor :watch

    # The destination Hash in canonical hash form. Example:
    # { true => :up, false => :restart}
    attr_accessor :destination

    # The Array of Condition instances.
    attr_accessor :conditions

    # Initialize a new Metric.
    #
    # watch       - The Watch.
    # destination - The optional destination Hash in canonical hash form.
    def initialize(watch, destination = nil)
      self.watch = watch
      self.destination = destination
      self.conditions = []
    end

    # Public: Instantiate the given Condition and pass it into the optional
    # block. Attributes of the condition must be set in the config file.
    #
    # kind - The Symbol name of the condition.
    #
    # Returns nothing.
    def condition(kind)
      # Create the condition.
      begin
        c = Condition.generate(kind, self.watch)
      rescue NoSuchConditionError => e
        abort e.message
      end

      # Send to block so config can set attributes.
      yield(c) if block_given?

      # Prepare the condition.
      c.prepare

      # Test generic and specific validity.
      unless Condition.valid?(c) && c.valid?
        abort "Exiting on invalid condition"
      end

      # Inherit interval from watch if no poll condition specific interval was
      # set.
      if c.kind_of?(PollCondition) && !c.interval
        if self.watch.interval
          c.interval = self.watch.interval
        else
          abort "No interval set for Condition '#{c.class.name}' in Watch " +
                "'#{self.watch.name}', and no default Watch interval from " +
                "which to inherit."
        end
      end

      # Add the condition to the list.
      self.conditions << c
    end

    # Enable all of this Metric's conditions. Poll conditions will be
    # scheduled and event/trigger conditions will be registered.
    #
    # Returns nothing.
    def enable
      self.conditions.each do |c|
        self.watch.attach(c)
      end
    end

    # Disable all of this Metric's conditions. Poll conditions will be
    # halted and event/trigger conditions will be deregistered.
    #
    # Returns nothing.
    def disable
      self.conditions.each do |c|
        self.watch.detach(c)
      end
    end
  end
end
