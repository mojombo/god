module God
  class Process
    attr_accessor :name, :start, :stop, :pidfile, :user, :group
    
    def initialize(options={})
      options.each do |k,v|
        send("#{k}=", v)
      end
    end
  end
end
