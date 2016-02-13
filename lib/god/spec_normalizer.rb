module God

  class SpecNormalizer

    class << self
      def normalize(spec)
        @spec_normalizer ||= SpecNormalizer.new
        @spec_normalizer.normalize(spec)
      end
    end

    NORMALIZE_METHODS = {
      String => :normalize_string,
      Array => :normalize_array,
      Hash => :normalize_hash
    }

    def find_method_for_current_spec
      NORMALIZE_METHODS.fetch(@spec.class, nil)
    end

    def normalize(spec)
      @spec = spec
      if method = find_method_for_current_spec
        send(method)
      else
        raise ArgumentError.new("must be a String (contact name), Array (of contact names), or Hash (contact specification)")
      end
    end

    def check_if_empty_or_raise_error(obj, error_msg)
      raise ArgumentError.new(error_msg) unless obj.select { |x| !x.instance_of?(String) }.empty?
    end

    def normalize_string
      { :contacts => Array(@spec) }
    end

    def normalize_array
      check_if_empty_or_raise_error @spec, "contains non-String elements"
      { :contacts => @spec }
    end

    def normalize_hash
      copy = @spec.dup

      # check :contacts
      if contacts = copy.delete(:contacts)
        case contacts
        when String
          # valid
        when Array
          check_if_empty_or_raise_error contacts, "has a :contacts key containing non-String elements"
          # valid
        else
          raise ArgumentError.new("must have a :contacts key pointing to a String or Array of Strings")
        end
      else
        raise ArgumentError.new("must have a :contacts key")
      end

      # remove priority and category
      copy.delete(:priority)
      copy.delete(:category)

      # check for invalid keys
      raise ArgumentError.new("contains extra elements: #{copy.inspect}") unless copy.empty?

      # normalize
      @spec[:contacts] &&= [*@spec[:contacts]]
      @spec[:priority] &&= @spec[:priority].to_s
      @spec[:category] &&= @spec[:category].to_s
      @spec
    end
  end

end
