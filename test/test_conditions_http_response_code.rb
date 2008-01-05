require File.dirname(__FILE__) + '/helper'

class TestHttpResponseCode < Test::Unit::TestCase
  def valid_condition
    c = Conditions::HttpResponseCode.new()
    c.watch = stub(:name => 'foo')
    c.host = 'localhost'
    c.port = 8080
    c.path = '/'
    c.timeout = 10
    c.code_is = 200
    c.times = 1
    yield(c) if block_given?
    c.prepare
    c
  end
  
  # valid?
  
  def test_valid_condition_is_valid
    c = valid_condition
    assert c.valid?
  end
  
  def test_valid_should_return_false_if_both_code_is_and_code_is_not_are_set
    c = valid_condition do |cc|
      cc.code_is_not = 500
    end
    no_stdout { assert !c.valid? }
  end
  
  def test_valid_should_return_false_if_no_host_set
    c = valid_condition do |cc|
      cc.host = nil
    end
    no_stdout { assert !c.valid? }
  end
  
  # test
  
  def test_test_should_return_false_if_code_is_is_set_to_200_but_response_is_500
    c = valid_condition
    Net::HTTP.expects(:start).yields(stub(:read_timeout= => nil, :get => stub(:code => 500)))
    assert_equal false, c.test
  end
  
  def test_test_should_return_false_if_code_is_not_is_set_to_200_and_response_is_200
    c = valid_condition do |cc|
      cc.code_is = nil
      cc.code_is_not = [200]
    end
    Net::HTTP.expects(:start).yields(stub(:read_timeout= => nil, :get => stub(:code => 200)))
    assert_equal false, c.test
  end
  
  def test_test_should_return_true_if_code_is_is_set_to_200_and_response_is_200
    c = valid_condition
    Net::HTTP.expects(:start).yields(stub(:read_timeout= => nil, :get => stub(:code => 200)))
    assert_equal true, c.test
  end
  
  def test_test_should_return_false_if_code_is_not_is_set_to_200_but_response_is_500
    c = valid_condition do |cc|
      cc.code_is = nil
      cc.code_is_not = [200]
    end
    Net::HTTP.expects(:start).yields(stub(:read_timeout= => nil, :get => stub(:code => 500)))
    assert_equal true, c.test
  end
  
  def test_test_should_return_false_if_code_is_is_set_to_200_but_response_times_out
    c = valid_condition
    Net::HTTP.expects(:start).raises(Timeout::Error, '')
    assert_equal false, c.test
  end
  
  def test_test_should_return_true_if_code_is_not_is_set_to_200_and_response_times_out
    c = valid_condition do |cc|
      cc.code_is = nil
      cc.code_is_not = [200]
    end
    Net::HTTP.expects(:start).raises(Timeout::Error, '')
    assert_equal true, c.test
  end
  
  def test_test_should_return_false_if_code_is_is_set_to_200_but_cant_connect
    c = valid_condition
    Net::HTTP.expects(:start).raises(Errno::ECONNREFUSED, '')
    assert_equal false, c.test
  end
  
  def test_test_should_return_true_if_code_is_not_is_set_to_200_and_cant_connect
    c = valid_condition do |cc|
      cc.code_is = nil
      cc.code_is_not = [200]
    end
    Net::HTTP.expects(:start).raises(Errno::ECONNREFUSED, '')
    assert_equal true, c.test
  end
  
  def test_test_should_return_true_if_code_is_is_set_to_200_and_response_is_200_twice_for_times_two_of_two
    c = valid_condition do |cc|
      cc.times = [2, 2]
    end
    Net::HTTP.expects(:start).yields(stub(:read_timeout= => nil, :get => stub(:code => 200))).times(2)
    assert_equal false, c.test
    assert_equal true, c.test
  end
end