require File.dirname(__FILE__) + '/helper'

class TestConditionsSocketResponding < Test::Unit::TestCase
#  def setup
#  #@socket = God::Conditions::SocketResponding.new
#    @socket = Conditions::ProcessRunning.new
#  end

  # valid?

  def test_valid_should_return_true_if_required_options_set
    c = Conditions::SocketResponding.new
    c.valid?
  end

end
