$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# internal requires
require 'god/base'
require 'god/errors'

require 'god/system/process'

require 'god/condition'
require 'god/process_condition'
require 'god/conditions/timeline'
require 'god/conditions/process_not_running'
require 'god/conditions/memory_usage'
require 'god/conditions/cpu_usage'
require 'god/conditions/always'

require 'god/watch'
require 'god/meddle'

module God
  VERSION = '0.1.0'
  
  def self.meddle
    m = Meddle.new
    yield m
    m.monitor
  end  
end