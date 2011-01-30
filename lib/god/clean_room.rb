module God

  # This class provides a simple clean room with
  # a class method returning a safe environment/binding
  class CleanRoom

    instance_methods.each do |m|
      undef_method m unless m.to_s =~ /^__|method_missing|respond_to?/
    end

    def self.safe_binding
      binding
    end

  end

end