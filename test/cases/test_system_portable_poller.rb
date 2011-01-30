require 'helper'

class TestSystemPortablePoller < Test::Unit::TestCase

  def setup
    @poller = System::PortablePoller.new(100)
  end

  def test_memory
    System::PortablePoller.any_instance.stubs(:ps_command).with('rss').returns("   608\n")

    assert_equal 608, @poller.memory
  end

  def test_percent_memory
    System::PortablePoller.any_instance.stubs(:ps_command).with('%mem').returns(" 10.0\n")

    assert_equal 10.0, @poller.percent_memory
  end

  def test_percent_cpu
    System::PortablePoller.any_instance.stubs(:ps_command).with('%cpu').returns(" 10.0\n")

    assert_equal 10.0, @poller.percent_cpu
  end

end

