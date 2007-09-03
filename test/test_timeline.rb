require File.dirname(__FILE__) + '/helper'

class TestTimeline < Test::Unit::TestCase
  def setup
    @timeline = Timeline.new(5)
  end
  
  def test_new_should_be_empty
    assert_equal 0, @timeline.size
  end
  
  def test_should_not_grow_to_more_than_size
    (1..10).each do |i|
      @timeline.push(i)
    end
    
    assert_equal [6, 7, 8, 9, 10], @timeline
  end
  
  def test_clear_should_clear_array
    @timeline.push(1)
    assert_equal [], @timeline.clear
  end
end
