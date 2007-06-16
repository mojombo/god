$:.unshift File.dirname(__FILE__)     # For use/testing when no gem is installed

# internal requires
require 'god/base'
require 'god/errors'
require 'god/condition'
require 'god/watch'
require 'god/meddle'
require 'god/conditions/process_not_running'

module God
  VERSION = '0.1.0'
  
  def self.meddle
    m = Meddle.new
    yield m
    m.monitor
  end  
end