#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestProwl < Test::Unit::TestCase

  #def setup
  #  @prowl = God::Contacts::Prowl.new
  #  @prowl.apikey = ''
  #  @prowl.priority = 2
  #  @prowl.application = 'God'
  #  @prowl.event = 'Test'
  #  @prowl.description = 'Testing Prowly as notification option in God'
  #end

  #def test_notify
  #  assert_nothing_raised do
  #    @prowl.notify(:a, :b, :c, :d, :e)
  #    assert_equal "", @prowl.info
  #  end
  #end
  
  def test_live_notify

    prowl = God::Contacts::Prowl.new
    prowl.name = "Raf"
    prowl.apikey = ''
    prowl.priority = 2
    prowl.application = 'God'
    prowl.event = 'Test'
    prowl.description = 'Testing Prowly as notification option in God'
    
    prowl.notify("Hello", Time.now, "Test", "Test", "")
    assert_equal "sent prowl notification to #{recipient}", prowl.info
  end
end