require File.dirname(__FILE__) + '/helper'

class TestConditionsProcessRunning < Test::Unit::TestCase
  def test_missing_pid_file_returns_opposite
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      c.stubs(:watch).returns(stub(:pid => 99999999, :name => 'foo'))
    
      # no_stdout do
        assert_equal !r, c.test
      # end
    end
  end
  
  def test_not_running_returns_opposite
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      File.stubs(:exist?).returns(true)
      c.stubs(:watch).returns(stub(:pid => 123))
      File.stubs(:read).returns('5')
      System::Process.any_instance.stubs(:exists?).returns(false)
    
      assert_equal !r, c.test
    end
  end
  
  def test_running_returns_same
    [true, false].each do |r|
      c = Conditions::ProcessRunning.new
      c.running = r
    
      File.stubs(:exist?).returns(true)
      c.stubs(:watch).returns(stub(:pid => 123))
      File.stubs(:read).returns('5')
      System::Process.any_instance.stubs(:exists?).returns(true)
    
      assert_equal r, c.test
    end
  end
end