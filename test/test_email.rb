require File.dirname(__FILE__) + '/helper'

class TestEmail < Test::Unit::TestCase
  def setup
    God::Contacts::Email.to_email = 'dev@example.com'
    God::Contacts::Email.from_email = 'god@example.com'
    @email = God::Contacts::Email.new
  end

  def test_validity_delivery
    @email.delivery_method = :brainwaves
    assert_equal false, @email.valid?
  end

  def test_smtp_delivery_method_for_notify
    @email.delivery_method = :smtp

    God::Contacts::Email.any_instance.expects(:notify_sendmail).never
    God::Contacts::Email.any_instance.expects(:notify_smtp).once.returns(nil)

    @email.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "sent email to dev@example.com via smtp", @email.info
  end

  def test_sendmail_delivery_method_for_notify
    @email.delivery_method = :sendmail

    God::Contacts::Email.any_instance.expects(:notify_smtp).never
    God::Contacts::Email.any_instance.expects(:notify_sendmail).once.returns(nil)

    @email.notify('msg', Time.now, 'prio', 'cat', 'host')
    assert_equal "sent email to dev@example.com via sendmail", @email.info
  end
end
