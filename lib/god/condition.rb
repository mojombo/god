module God

  class Condition < Behavior
    attr_accessor :transition, :notify, :info, :phase

    # Generate a Condition of the given kind. The proper class if found by camel casing the
    # kind (which is given as an underscored symbol).
    #   +kind+ is the underscored symbol representing the class (e.g. :foo_bar for God::Conditions::FooBar)
    def self.generate(kind, watch)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      c = God::Conditions.const_get(sym).new

      unless c.kind_of?(PollCondition) || c.kind_of?(EventCondition) || c.kind_of?(TriggerCondition)
        abort "Condition '#{c.class.name}' must subclass God::PollCondition, God::EventCondition, or God::TriggerCondition"
      end

      if !EventHandler.loaded? && c.kind_of?(EventCondition)
        abort "Condition '#{c.class.name}' requires an event system but none has been loaded"
      end

      c.watch = watch
      c
    rescue NameError
      raise NoSuchConditionError.new("No Condition found with the class name God::Conditions::#{sym}")
    end

    def self.valid?(condition)
      valid = true
      if condition.notify
        begin
          Contact.normalize(condition.notify)
        rescue ArgumentError => e
          valid &= Configurable.complain("Attribute 'notify' " + e.message, condition)
        end
      end
      valid
    end

    # Construct the friendly name of this Condition, looks like:
    #
    # Condition FooBar on Watch 'baz'
    def friendly_name
      "Condition #{self.class.name.split('::').last} on Watch '#{self.watch.name}'"
    end
  end

  class PollCondition < Condition
    # all poll conditions can specify a poll interval
    attr_accessor :interval

    # Override this method in your Conditions (optional)
    def before
    end

    # Override this method in your Conditions (mandatory)
    #
    # Return true if the test passes (everything is ok)
    # Return false otherwise
    def test
      raise AbstractMethodNotOverriddenError.new("PollCondition#test must be overridden in subclasses")
    end

    # Override this method in your Conditions (optional)
    def after
    end
  end

  class EventCondition < Condition
    def register
      raise AbstractMethodNotOverriddenError.new("EventCondition#register must be overridden in subclasses")
    end

    def deregister
      raise AbstractMethodNotOverriddenError.new("EventCondition#deregister must be overridden in subclasses")
    end
  end

  class TriggerCondition < Condition
    def process(event, payload)
      raise AbstractMethodNotOverriddenError.new("TriggerCondition#process must be overridden in subclasses")
    end

    def trigger
      self.watch.trigger(self)
    end

    def register
      Trigger.register(self)
    end

    def deregister
      Trigger.deregister(self)
    end
  end

end
