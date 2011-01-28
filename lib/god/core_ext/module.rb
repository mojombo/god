module God
  module CoreExt

    module Module
      def safe_attr_accessor(*args)
        args.each do |arg|
          define_method((arg.to_s + "=").intern) do |other|
            if !self.running && self.inited
              abort "God.#{arg} must be set before any Tasks are defined"
            end

            if self.running && self.inited
              applog(nil, :warn, "God.#{arg} can't be set while god is running")
              return
            end

            instance_variable_set(('@' + arg.to_s).intern, other)
          end

          define_method(arg) do
            instance_variable_get(('@' + arg.to_s).intern)
          end
        end
      end
    end

  end
end

Module.send(:include, God::CoreExt::Module)