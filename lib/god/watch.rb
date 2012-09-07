require 'etc'
require 'forwardable'

module God
  # The Watch class is a specialized Task that handles standard process
  # workflows. It has four states: init, up, start, and restart.
  class Watch < Task
    # The Array of Symbol valid task states.
    VALID_STATES = [:init, :up, :start, :restart]

    # The Sybmol initial state.
    INITIAL_STATE = :init

    # Public: The grace period for this process (seconds).
    attr_accessor :grace

    # Public: The start grace period (seconds).
    attr_accessor :start_grace

    # Public: The stop grace period (seconds).
    attr_accessor :stop_grace

    # Public: The restart grace period (seconds).
    attr_accessor :restart_grace

    # Public: God::Process delegators. See lib/god/process.rb for docs.
    extend Forwardable
    def_delegators :@process, :name, :uid, :gid, :start, :stop, :restart, :dir,
                              :name=, :uid=, :gid=, :start=, :stop=, :restart=,
                              :dir=, :pid_file, :pid_file=, :log, :log=,
                              :log_cmd, :log_cmd=, :err_log, :err_log=,
                              :err_log_cmd, :err_log_cmd=, :alive?, :pid,
                              :unix_socket, :unix_socket=, :chroot, :chroot=,
                              :env, :env=, :signal, :stop_timeout=,
                              :stop_signal=, :umask, :umask=

    # Initialize a new Watch instance.
    def initialize
      super

      # This God::Process instance holds information specific to the process.
      @process = God::Process.new

      # Valid states.
      self.valid_states = VALID_STATES
      self.initial_state = INITIAL_STATE

      # No grace period by default.
      self.grace = self.start_grace = self.stop_grace = self.restart_grace = 0
    end

    # Is this Watch valid?
    #
    # Returns true if the Watch is valid, false if not.
    def valid?
      super && @process.valid?
    end

    ###########################################################################
    #
    # Behavior
    #
    ###########################################################################

    # Public: Add a behavior to this Watch. See lib/god/behavior.rb.
    #
    # kind - The Symbol name of the Behavior to add.
    #
    # Yields the newly instantiated Behavior.
    #
    # Returns nothing.
    def behavior(kind)
      # Create the behavior.
      begin
        b = Behavior.generate(kind, self)
      rescue NoSuchBehaviorError => e
        abort e.message
      end

      # Send to block so config can set attributes.
      yield(b) if block_given?

      # Abort if the Behavior is invalid, the Behavior will have printed
      # out its own error messages by now.
      abort unless b.valid?

      self.behaviors << b
    end

    ###########################################################################
    #
    # Quickstart mode
    #
    ###########################################################################

    # Default Integer interval at which keepalive will runn poll checks.
    DEFAULT_KEEPALIVE_INTERVAL = 5.seconds

    # Default Integer or Array of Integers specification of how many times the
    # memory condition must fail before triggering.
    DEFAULT_KEEPALIVE_MEMORY_TIMES = [3, 5]

    # Default Integer or Array of Integers specification of how many times the
    # CPU condition must fail before triggering.
    DEFAULT_KEEPALIVE_CPU_TIMES = [3, 5]

    # Public: A set of conditions for easily getting started with simple watch
    # scenarios. Keepalive is intended for use by beginners or on processes
    # that do not need very sophisticated monitoring.
    #
    # If events are enabled, it will use the :process_exit event to determine
    # if a process fails. Otherwise it will use the :process_running poll.
    #
    # options - The option Hash. Possible values are:
    #           :interval -     The Integer number of seconds on which to poll
    #                           for process status. Affects CPU, memory, and
    #                           :process_running conditions (if used).
    #                           Default: 5.seconds.
    #           :memory_max   - The Integer memory max. A bare integer means
    #                           kilobytes. You may use Numeric.kilobytes,
    #                           Numeric#megabytes, and Numeric#gigabytes to
    #                           makes things more clear.
    #           :memory_times - If :memory_max is set, :memory_times can be
    #                           set to either an Integer or a 2 element
    #                           Integer Array to specify the number of times
    #                           the memory condition must fail. Examples:
    #                           3 (three times), [3, 5] (three out of any five
    #                           checks). Default: [3, 5].
    #           :cpu_max      - The Integer CPU percentage max. Range is
    #                           0 to 100. You may use the Numberic#percent
    #                           sugar to clarify e.g. 50.percent.
    #           :cpu_times    - If :cpu_max is set, :cpu_times can be
    #                           set to either an Integer or a 2 element
    #                           Integer Array to specify the number of times
    #                           the memory condition must fail. Examples:
    #                           3 (three times), [3, 5] (three out of any five
    #                           checks). Default: [3, 5].
    def keepalive(options = {})
      if God::EventHandler.loaded?
        self.transition(:init, { true => :up, false => :start }) do |on|
          on.condition(:process_running) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.running = true
          end
        end

        self.transition([:start, :restart], :up) do |on|
          on.condition(:process_running) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.running = true
          end
        end

        self.transition(:up, :start) do |on|
          on.condition(:process_exits)
        end
      else
        self.start_if do |start|
          start.condition(:process_running) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.running = false
          end
        end
      end

      self.restart_if do |restart|
        if options[:memory_max]
          restart.condition(:memory_usage) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.above = options[:memory_max]
            c.times = options[:memory_times] || DEFAULT_KEEPALIVE_MEMORY_TIMES
          end
        end

        if options[:cpu_max]
          restart.condition(:cpu_usage) do |c|
            c.interval = options[:interval] || DEFAULT_KEEPALIVE_INTERVAL
            c.above = options[:cpu_max]
            c.times = options[:cpu_times] || DEFAULT_KEEPALIVE_CPU_TIMES
          end
        end
      end
    end

    ###########################################################################
    #
    # Simple mode
    #
    ###########################################################################

    # Public: Start the process if any of the given conditions are triggered.
    #
    # Yields the Metric upon which conditions can be added.
    #
    # Returns nothing.
    def start_if
      self.transition(:up, :start) do |on|
        yield(on)
      end
    end

    # Public: Restart the process if any of the given conditions are triggered.
    #
    # Yields the Metric upon which conditions can be added.
    #
    # Returns nothing.
    def restart_if
      self.transition(:up, :restart) do |on|
        yield(on)
      end
    end

    # Public: Stop the process if any of the given conditions are triggered.
    #
    # Yields the Metric upon which conditions can be added.
    #
    # Returns nothing.
    def stop_if
      self.transition(:up, :stop) do |on|
        yield(on)
      end
    end

    ###########################################################################
    #
    # Lifecycle
    #
    ###########################################################################

    # Enable monitoring. Start at the first available of the init or up states.
    #
    # Returns nothing.
    def monitor
      if !self.metrics[:init].empty?
        self.move(:init)
      else
        self.move(:up)
      end
    end

    ###########################################################################
    #
    # Actions
    #
    ###########################################################################

    # Perform an action.
    #
    # a - The Symbol action to perform. One of :start, :restart, :stop.
    # c - The Condition.
    #
    # Returns this Watch.
    def action(a, c = nil)
      if !self.driver.in_driver_context?
        # Called from outside Driver. Send an async message to Driver.
        self.driver.message(:action, [a, c])
      else
        # Called from within Driver.
        case a
        when :start
          call_action(c, :start)
          sleep(self.start_grace + self.grace)
        when :restart
          if self.restart
            call_action(c, :restart)
          else
            action(:stop, c)
            action(:start, c)
          end
          sleep(self.restart_grace + self.grace)
        when :stop
          call_action(c, :stop)
          sleep(self.stop_grace + self.grace)
        end
      end

      self
    end

    # Perform the specifics of the action.
    #
    # condition - The Condition.
    # action    - The Symbol action.
    #
    # Returns nothing.
    def call_action(condition, action)
      # Before.
      before_items = self.behaviors
      before_items += [condition] if condition
      before_items.each do |b|
        info = b.send("before_#{action}")
        if info
          msg = "#{self.name} before_#{action}: #{info} (#{b.base_name})"
          applog(self, :info, msg)
        end
      end

      # Log.
      if self.send(action)
        msg = "#{self.name} #{action}: #{self.send(action).to_s}"
        applog(self, :info, msg)
      end

      # Execute.
      @process.call_action(action)

      # After.
      after_items = self.behaviors
      after_items += [condition] if condition
      after_items.each do |b|
        info = b.send("after_#{action}")
        if info
          msg = "#{self.name} after_#{action}: #{info} (#{b.base_name})"
          applog(self, :info, msg)
        end
      end
    end

    ###########################################################################
    #
    # Registration
    #
    ###########################################################################

    # Register the Process in the global process registry.
    #
    # Returns nothing.
    def register!
      God.registry.add(@process)
    end

    # Unregister the Process in the global process registry.
    #
    # Returns nothing.
    def unregister!
      God.registry.remove(@process)
      super
    end
  end
end
