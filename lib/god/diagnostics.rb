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
  
  class << self
    attr_accessor :logger
  end
  
  def self.install
    require 'bleak_house'
    self.logger = BleakHouse::Logger.new
    File.delete(LOG_FILE) rescue nil
  end
  
  def self.snapshot(name)
    self.logger.snapshot(LOG_FILE, name, false) if self.logger
  end
  
  def self.spin(delay = 1)
    Thread.new do
      loop do
        self.snapshot
        sleep(delay)
      end
    end
  end
end