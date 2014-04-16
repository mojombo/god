#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/helper'

class TestHttpPost < Test::Unit::TestCase
  def test_notify
    http_post = God::Contacts::HttpPost.new
    http_post.url = "http://localhost:4567"
    http_post.name = "HttpPost"

    God::Contacts::HttpPost.any_instance.expects(:notify).returns "foo"

    http_post.notify("Test message for http_post", Time.now, "http_post priority", "http_post category", "")
  end
end
