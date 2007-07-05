module God
  
  class Base
    def abort(msg)
      Kernel.abort(msg)
    end
  end
  
end