require File.dirname(__FILE__) + '/helper'

class TestContact < Test::Unit::TestCase
  def test_exists
    God::Contact
  end
end