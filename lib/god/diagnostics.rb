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