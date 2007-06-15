$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

require 'god/condition'
require 'god/watch'
require 'god/conditions/process_not_running'

module God
  VERSION = '0.1.0'
  
  class AbstractMethodNotOverriddenError < StandardError
  end
  
  def self.meddle
    m = Meddle.new
    yield m
    m.monitor
  end
  
  class Meddle
    attr_accessor :interval
    
    def initialize
      @watches = []
    end
    
    def settings
    
    end
  
    def watch
      w = Watch.new
      yield(w)
      @watches << w
    end
    
    def monitor
      threads = []
      @watches.each do |w|
        t = Thread.new do
          while true do
            if a = w.run
              w.action(a)
            end
            sleep self.interval
          end
        end
        t.join
        threads << t
      end
    end
  end
end