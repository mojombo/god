require File.dirname(__FILE__) + '/helper'

class TestWatch < Test::Unit::TestCase
  def setup
    @watch = Watch.new(nil)
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
      @watch.start = 'start'
      @watch.stop = 'stop'
      @watch.restart = 'restart'
      @watch.interval = 30
      @watch.grace = 5
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
  
  def test_start_condition_should_record_condition_in_correct_list
    cond = nil
    @watch.interval = 0
    @watch.start_if do |w|
      w.condition(:fake_poll_condition) { |c| cond = c }
    end
    assert_equal 1, @watch.conditions[:start].size
    assert_equal cond, @watch.conditions[:start].first
  end
  
  def test_restart_condition_should_record_condition_in_correct_list
    cond = nil
    @watch.interval = 0
    @watch.restart_if do |w|
      w.condition(:fake_poll_condition) { |c| cond = c }
    end
    assert_equal 1, @watch.conditions[:restart].size
    assert_equal cond, @watch.conditions[:restart].first
  end
  
  def test_condition_called_from_outside_if_block_should_raise
    assert_raise AbortCalledError do
      @watch.condition(:fake_poll_condition) { |c| cond = c }
    end
  end
  
  def test_condition_should_be_block_optional
    @watch.interval = 0
    @watch.start_if do |w|
      w.condition(:always)
    end
    assert_equal 1, @watch.conditions[:start].size
  end
  
  def test_poll_condition_should_inherit_interval_from_watch_if_not_specified
    @watch.interval = 27
    @watch.start_if do |w|
      w.condition(:fake_poll_condition)
    end
    assert_equal 27, @watch.conditions[:start].first.interval
  end
  
  def test_poll_condition_should_abort_if_no_interval_and_no_watch_interval
    assert_raise AbortCalledError do
      @watch.start_if do |w|
        w.condition(:fake_poll_condition)
      end
    end
  end
  
  def test_condition_should_allow_generation_of_subclasses_of_poll_or_event
    @watch.interval = 27
    assert_nothing_raised do
      @watch.start_if do |w|
        w.condition(:fake_poll_condition)
        w.condition(:fake_event_condition)
      end
    end
  end
  
  def test_condition_should_abort_if_not_subclass_of_poll_or_event
    assert_raise AbortCalledError do
      @watch.start_if do |w|
        w.condition(:fake_condition) { |c| }
      end
    end
  end

  # behavior
  
  def test_behavior_should_record_behavior
    beh = nil
    @watch.behavior(:fake_behavior) { |b| beh = b }
    assert_equal 1, @watch.behaviors.size
    assert_equal beh, @watch.behaviors.first
  end
  
  # canonical hash form
  
  def test_canonical_hash_form_should_convert_symbol_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(:foo))
  end
  
  def test_canonical_hash_form_should_convert_hash_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(true => :foo))
  end
end