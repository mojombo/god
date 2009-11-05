def start_dike
  require 'dike'
  Thread.new do
    Dike.logfactory File.join(File.dirname(__FILE__), *%w[.. .. logs])
    loop do
      Dike.finger
      sleep(1)
    end
  end
end

class BleakHouseDiagnostic
  LOG_FILE = File.join(File.dirname(__FILE__), *%w[.. .. logs bleak.log])
  
  def self.install
    require 'snapshot'
    self.spin
  end
  
  def self.snapshot
    @count ||= 0
    filename = "/tmp/god-bleak-%s-%03i.dump" % [Process.pid,@count]
    STDERR.puts "** BleakHouse: working..."
    BleakHouse.ext_snapshot(filename, 3)
    STDERR.puts "** BleakHouse: complete\n** Bleakhouse: Run 'bleak #{filename}' to analyze."
    @count += 1
  end
  
  def self.spin(delay = 60)
    Thread.new do
      loop do
        sleep(delay)
        self.snapshot
      end
    end
  end
end
