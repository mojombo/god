require File.dirname(__FILE__) + '/helper'

class TestContact < Test::Unit::TestCase
  def test_exists
    God::Contact
  end

  # generate

  def test_generate_should_raise_on_invalid_kind
    assert_raise(NoSuchContactError) do
      Contact.generate(:invalid)
    end
  end

  def test_generate_should_abort_on_invalid_contact
    assert_abort do
      Contact.generate(:invalid_contact)
    end
  end

  # normalize

  def test_normalize_should_accept_a_string
    input = 'tom'
    output = {:contacts => ['tom']}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_accept_an_array_of_strings
    input = ['tom', 'kevin']
    output = {:contacts => ['tom', 'kevin']}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_accept_a_hash_with_contacts_string
    input = {:contacts => 'tom'}
    output = {:contacts => ['tom']}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_accept_a_hash_with_contacts_array_of_strings
    input = {:contacts => ['tom', 'kevin']}
    output = {:contacts => ['tom', 'kevin']}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_stringify_priority
    input = {:contacts => 'tom', :priority => 1}
    output = {:contacts => ['tom'], :priority => '1'}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_stringify_category
    input = {:contacts => 'tom', :category => :product}
    output = {:contacts => ['tom'], :category => 'product'}
    assert_equal(output, Contact.normalize(input))
  end

  def test_normalize_should_raise_on_non_string_array_hash
    input = 1
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  def test_normalize_should_raise_on_non_string_array_contacts_key
    input = {:contacts => 1}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  def test_normalize_should_raise_on_non_string_containing_array
    input = [1]
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  def test_normalize_should_raise_on_non_string_containing_array_contacts_key
    input = {:contacts => [1]}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  def test_normalize_should_raise_on_absent_contacts_key
    input = {}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  def test_normalize_should_raise_on_extra_keys
    input = {:contacts => ['tom'], :priority => 1, :category => 'product', :extra => 'foo'}
    assert_raise ArgumentError do
      Contact.normalize(input)
    end
  end

  # notify

  def test_notify_should_be_abstract
    assert_raise(AbstractMethodNotOverriddenError) do
      Contact.new.notify(:a, :b, :c, :d, :e)
    end
  end
end
