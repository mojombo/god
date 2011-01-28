module God
  module CoreExt

    module Kernel
      alias_method :abort_orig, :abort

      def abort(text = nil)
        $run = false
        applog(nil, :error, text) if text
        exit(1)
      end

      alias_method :exit_orig, :exit

      def exit(code = 0)
        $run = false
        exit_orig(code)
      end
    end

  end
end

Kernel.send(:include, God::CoreExt::Kernel)