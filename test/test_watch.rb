require File.dirname(__FILE__) + '/helper'

class TestWatch < Test::Unit::TestCase
  def setup
    @watch = Watch.new(nil)
  end
  
  # new
  
  def test_new_should_have_no_behaviors
    assert_equal [], @watch.behaviors
  end
  
  def test_new_should_have_no_metrics
    Watch::VALID_STATES.each do |state|
      assert_equal [], @watch.metrics[state]
    end
  end
    
  def test_new_should_have_standard_attributes
    assert_nothing_raised do
      @watch.name = 'foo'
      @watch.start = 'start'
      @watch.stop = 'stop'
      @watch.restart = 'restart'
      @watch.interval = 30
      @watch.grace = 5
    end
  end
  
  def test_new_should_have_nil_state
    assert_equal nil, @watch.state
  end
  
  # mutex
  
  def test_mutex_should_return_the_same_mutex_each_time
    assert_equal @watch.mutex, @watch.mutex
  end
  
  # behavior
  
  def test_behavior_should_record_behavior
    beh = nil
    @watch.behavior(:fake_behavior) { |b| beh = b }
    assert_equal 1, @watch.behaviors.size
    assert_equal beh, @watch.behaviors.first
  end
  
  # transition
  
  def test_transition_should_abort_on_invalid_start_state
    assert_raise AbortCalledError do
      @watch.transition(:foo, :bar)
    end
  end
  
  def test_transition_should_accept_all_valid_start_states
    assert_nothing_raised do
      Watch::VALID_STATES.each do |state|
        @watch.transition(state, :bar) { }
      end
    end
  end
  
  def test_transition_should_create_and_record_a_metric_for_the_given_start_state
    @watch.transition(:init, :start) { }
    assert_equal 1, @watch.metrics[:init].size
  end
  
  # start_if
  
  def test_start_if_should_place_a_metric_on_up_state
    @watch.start_if { }
    assert_equal 1, @watch.metrics[:up].size
  end
  
  # restart_if
  
  def test_restart_if_should_place_a_metric_on_up_state
    @watch.restart_if { }
    assert_equal 1, @watch.metrics[:up].size
  end
  
  # canonical_hash_form
  
  def test_canonical_hash_form_should_convert_symbol_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(:foo))
  end
  
  def test_canonical_hash_form_should_convert_hash_to_hash
    assert_equal({true => :foo}, @watch.canonical_hash_form(true => :foo))
  end
end