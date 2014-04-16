module God

  class Contact
    include Configurable

    attr_accessor :name, :group, :info

    def self.generate(kind)
      sym = kind.to_s.capitalize.gsub(/_(.)/){$1.upcase}.intern
      c = God::Contacts.const_get(sym).new

      unless c.kind_of?(Contact)
        abort "Contact '#{c.class.name}' must subclass God::Contact"
      end

      c
    rescue NameError
      raise NoSuchContactError.new("No Contact found with the class name God::Contacts::#{sym}")
    end

    def self.valid?(contact)
      valid = true
      valid &= Configurable.complain("Attribute 'name' must be specified", contact) if contact.name.nil?
    end

    def self.defaults
      yield self
    end

    def arg(name)
      self.instance_variable_get("@#{name}") || self.class.instance_variable_get("@#{name}")
    end

    # Normalize the given notify specification into canonical form.
    #   +spec+ is the notify spec as a String, Array of Strings, or Hash
    #
    # Canonical form looks like:
    # {:contacts => ['fred', 'john'], :priority => '1', :category => 'awesome'}
    # Where :contacts will be present and point to an Array of Strings. Both
    # :priority and :category may not be present but if they are, they will each
    # contain a single String.
    #
    # Returns normalized notify spec
    # Raises ArgumentError on invalid spec (message contains details)
    def self.normalize(spec)
      SpecNormalizer.normalize(spec)
    end

    # Abstract
    # Send the message to the external source
    #   +message+ is the message body returned from the condition
    #   +time+ is the Time at which the notification was made
    #   +priority+ is the arbitrary priority String
    #   +category+ is the arbitrary category String
    #   +host+ is the hostname of the server
    def notify(message, time, priority, category, host)
      raise AbstractMethodNotOverriddenError.new("Contact#notify must be overridden in subclasses")
    end

    # Construct the friendly name of this Contact, looks like:
    #
    # Contact FooBar
    def friendly_name
      super + " Contact '#{self.name}'"
    end
  end

end
