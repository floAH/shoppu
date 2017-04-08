require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  # test "the truth" do
  #   assert true
  # end

  test "password_reset" do
      user = users(:UserTwo)
      user.reset_token = User.new_token
      mail = UserMailer.password_reset(user)
      assert_equal "Password reset", mail.subject
      assert_equal [user.email], mail.to
      assert_equal ["shoppumail@gmail.com"], mail.from
      assert_match user.reset_token,        mail.body.encoded
      assert_match CGI::escape(user.email), mail.body.encoded
    end

end
