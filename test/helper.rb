require File.join(File.dirname(__FILE__), *%w[.. lib god])

require 'test/unit'
require 'set'

begin
  require 'mocha'
rescue LoadError
  unless gems ||= false
    require 'rubygems'
    gems = true
    retry
  else
    abort "=> You need the Mocha gem to run these tests."
  end
end

include God

module God
  class AbortCalledError < StandardError
  end

  module Conditions
    class FakeCondition < Condition
      def test
        true
      end
    end
  
    class FakePollCondition < PollCondition
      def test
        true
      end
    end
  
    class FakeEventCondition < EventCondition
      def test
        true
      end
    end
  end
  
  module Behaviors
    class FakeBehavior < Behavior
    end
  end
  
  def self.at_exit
    # disable at_exit
  end
  
  def self.reset
    self.watches = nil
    self.groups = nil
    self.server = nil
    self.inited = nil
    self.host = nil
    self.port = nil
    self.registry.reset
  end
end

module Kernel
  def abort(msg)
    raise God::AbortCalledError.new(msg)
  end
end

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

# This allows you to be a good OOP citizen and honor encapsulation, but
# still make calls to private methods (for testing) by doing
#
#   obj.bypass.private_thingie(arg1, arg2)
#
# Which is easier on the eye than
#
#   obj.send(:private_thingie, arg1, arg2)
#
class Object
  class Bypass
    instance_methods.each do |m|
      undef_method m unless m =~ /^__/
    end

    def initialize(ref)
      @ref = ref
    end
  
    def method_missing(sym, *args)
      @ref.__send__(sym, *args)
    end
  end

  def bypass
    Bypass.new(self)
  end
end
