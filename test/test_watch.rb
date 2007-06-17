require 'helper'

class TestWatch < Test::Unit::TestCase
  def setup
    @watch = Watch.new
  end
  
  def test_should_have_empty_start_conditions
    assert_equal [], @watch.conditions[:start]
  end
  
  def test_should_have_empty_restart_conditions
    assert_equal [], @watch.conditions[:restart]
  end
  
  def test_should_have_standard_attributes
    assert_nothing_raised do
      @watch.name = 'foo'
      @watch.cwd = '/foo'
      @watch.start = 'start'
      @watch.stop = 'stop'
      @watch.restart = 'restart'
    end
  end
  
  # _if methods
  
  def test_start_if_should_modify_action_within_scope
    assert_equal nil, @watch.instance_variable_get(:@action)
    @watch.start_if do |w|
      assert_equal :start, @watch.instance_variable_get(:@action)
    end
    assert_equal nil, @watch.instance_variable_get(:@action)
  end
  
  def test_restart_if_should_modify_action_within_scope
    assert_equal nil, @watch.instance_variable_get(:@action)
    @watch.restart_if do |w|
      assert_equal :restart, @watch.instance_variable_get(:@action)
    end
    assert_equal nil, @watch.instance_variable_get(:@action)
  end
  
  # condition
  
  def test_condition_should_record_condition_in_correct_list
    cond = nil
    @watch.start_if do |w|
      w.condition(:fake_condition) { |c| cond = c }
    end
    assert_equal 1, @watch.conditions[:start].size
    assert_equal cond, @watch.conditions[:start].first
  end
  
  def test_condition_should_record_condition_in_correct_list
    cond = nil
    @watch.restart_if do |w|
      w.condition(:fake_condition) { |c| cond = c }
    end
    assert_equal 1, @watch.conditions[:restart].size
    assert_equal cond, @watch.conditions[:restart].first
  end
  
  def test_condition_called_from_outside_if_block_should_raise
    assert_raise ExitCalledError do
      @watch.condition(:fake_condition) { |c| cond = c }
    end
  end
end