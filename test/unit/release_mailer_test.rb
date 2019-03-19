require 'test_helper'

class ReleaseMailerTest < ActionMailer::TestCase
  test "uploaded" do
    @expected.subject = 'ReleaseMailer#uploaded'
    @expected.body    = read_fixture('uploaded')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ReleaseMailer.create_uploaded(@expected.date).encoded
  end

  test "released" do
    @expected.subject = 'ReleaseMailer#released'
    @expected.body    = read_fixture('released')
    @expected.date    = Time.now

    assert_equal @expected.encoded, ReleaseMailer.create_released(@expected.date).encoded
  end

end
