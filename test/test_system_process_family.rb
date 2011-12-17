require 'drb/drb'
require 'ostruct'
require File.dirname(__FILE__) + '/helper'

class TestSystemProcessFamily < Test::Unit::TestCase
  DRUBY_URI = 'druby://localhost:38753'

  def setup
    pid = Process.pid
    @process = System::Process.new(pid)
  end

  def test_family_memory_usage
    pid = fork
    if pid.nil?
      my_process = System::Process.new(Process.pid)
      mem_before = my_process.memory
      # Allocate some memory.
      data = (0..10_000).reduce('') { |acc, int| acc + int.to_s }
      # Create an object which will be used to communicate with the parent
      # process.
      obj = OpenStruct.new :done => false,
        :used_memory => my_process.memory - mem_before
      DRb.start_service DRUBY_URI, obj
      at_exit { DRb.stop_service }
      sleep 0.1 while not obj.done
      exit 0
    else
      begin
        obj = DRbObject.new_with_uri DRUBY_URI
        allocated_by_child = obj.used_memory
        # Do the actual memory assertion.
        assert (@process.family_memory - @process.memory) > allocated_by_child
        # Ask the child process to die.
        obj.done = true
      rescue DRb::DRbConnError => e
        # Child's DRb service isn't running yet. Retry.
        sleep 0.1
        retry
      end
    end
  end
end

