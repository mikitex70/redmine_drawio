# frozen_string_literal: true

require 'test_helper'

module RedmineDrawio
  class ApiTokenTest < ActiveSupport::TestCase
    fixtures :users, :email_addresses, :roles

    def setup
      User.current = nil
      @user = User.find(2)
      @request = ActionDispatch::TestRequest.create
    end

    test 'should issue a token for a logged user' do
      assert_predicate ApiToken.issue(@user), :present?
    end

    test 'should issue a token for the anonymous user as well' do
      assert_predicate ApiToken.issue(User.anonymous), :present?
    end

    test 'should not issue a token for a missing user' do
      assert_predicate ApiToken.issue(nil), :blank?
    end

    test 'should not disclose the api key' do
      assert_not_includes ApiToken.issue(@user), @user.api_key
    end

    test 'should authenticate the user owning the token' do
      token = ApiToken.issue(@user)

      assert_equal @user, ApiToken.authenticate(request_with(token))
    end

    test 'should not authenticate without token' do
      assert_nil ApiToken.authenticate(request_with(nil))
    end

    test 'should not authenticate with a tampered token' do
      token = ApiToken.issue(@user)
      tampered = token[0..-2] + (token[-1] == 'a' ? 'b' : 'a')

      assert_nil ApiToken.authenticate(request_with(tampered))
    end

    test 'should not authenticate an expired token' do
      token = ApiToken.issue(@user)
      travel(ApiToken::TTL + 1.minute) do
        assert_nil ApiToken.authenticate(request_with(token))
      end
    end

    test 'should not authenticate a token issued for another purpose' do
      token = ApiToken.verifier.generate('another_purpose:2')

      assert_nil ApiToken.authenticate(request_with(token))
    end

    test 'should not authenticate a locked user' do
      token = ApiToken.issue(@user)
      User.find(2).update_column(:status, User::STATUS_LOCKED)

      assert_nil ApiToken.authenticate(request_with(token))
    end

    private

    def request_with(token)
      @request.headers[ApiToken::HEADER] = token if token
      @request
    end
  end
end