require 'helper'

class TestContact < Test::Unit::TestCase

  test "exists" do
    God::Contact
  end

  # generate

  test "generate should raise on invalid kind" do
    assert_raise(NoSuchContactError) do
      Contact.generate(:invalid)
    end
  end

  test "generate should abort on invalid contact" do
    assert_abort do
      Contact.generate(:invalid_contact)
    end
  end

  # normalize

  test "normalize should accept a string" do
    input = 'tom'
    output = { :contacts => ['tom'] }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should accept an array of strings" do
    input = ['tom', 'kevin']
    output = { :contacts => ['tom', 'kevin'] }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should accept a hash with contacts string" do
    input = { :contacts => 'tom' }
    output = { :contacts => ['tom'] }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should accept a hash with contacts array of strings" do
    input = { :contacts => ['tom', 'kevin'] }
    output = { :contacts => ['tom', 'kevin'] }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should stringify priority" do
    input = { :contacts => 'tom', :priority => 1 }
    output = { :contacts => ['tom'], :priority => '1' }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should stringify category" do
    input = { :contacts => 'tom', :category => :product }
    output = { :contacts => ['tom'], :category => 'product' }
    assert_equal(output, Contact.normalize(input))
  end

  test "normalize should raise on non string array hash" do
    input = 1
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  test "normalize should raise on non string array contacts key" do
    input = {:contacts => 1}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  test "normalize should raise on non string containing array" do
    input = [1]
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  test "normalize should raise on non string containing array contacts key" do
    input = { :contacts => [1] }
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  test "normalize should raise on absent contacts key" do
    input = {}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  test "normalize should raise on extra keys" do
    input = { :contacts => ['tom'], :priority => 1, :category => 'product', :extra => 'foo' }
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  # notify

  test "notify should be abstract" do
    assert_raise(AbstractMethodNotOverriddenError) do
      Contact.new.notify(:a, :b, :c, :d, :e)
    end
  end

end