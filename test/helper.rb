$:.unshift File.expand_path('../../lib', __FILE__) # For use/testing when no gem is installed

# Use this flag to actually load all of the god infrastructure
$load_god = true

require File.join(File.dirname(__FILE__), *%w[.. lib god sys_logger])
require File.join(File.dirname(__FILE__), *%w[.. lib god])
God::EventHandler.load

require 'test/unit'
require 'set'

include God

if Process.uid != 0 and RbConfig::CONFIG['host_os'] == "linux"
  abort <<-EOF
\n
*********************************************************************
*                                                                   *
*               You need to run these tests as root                 *
*           chroot and netlink (linux only) require it              *
*                                                                   *
*********************************************************************
EOF
end

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

module God
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
      def register
      end
      def deregister
      end
    end
  end

  module Behaviors
    class FakeBehavior < Behavior
      def before_start
        'foo'
      end
      def after_start
        'bar'
      end
    end
  end

  module Contacts
    class FakeContact < Contact
    end

    class InvalidContact
    end
  end

  def self.reset
    self.watches = nil
    self.groups = nil
    self.server = nil
    self.inited = nil
    self.host = nil
    self.port = nil
    self.pid_file_directory = nil
    self.registry.reset
  end
end

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

LOG.instance_variable_set(:@io, StringIO.new('/dev/null'))

module Kernel
  def abort(text)
    raise SystemExit
  end
  def exit(code)
    raise SystemExit
  end
end

module Test::Unit::Assertions
  def assert_abort
    assert_raise SystemExit do
      yield
    end
  end
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
      undef_method m unless m =~ /^(__|object_id)/
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
