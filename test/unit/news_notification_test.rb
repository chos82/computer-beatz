require 'test_helper'

class NewsNotificationTest < ActionMailer::TestCase
  test "notification" do
    @expected.subject = 'NewsNotification#notification'
    @expected.body    = read_fixture('notification')
    @expected.date    = Time.now

    assert_equal @expected.encoded, NewsNotification.create_notification(@expected.date).encoded
  end

end
