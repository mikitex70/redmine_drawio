# frozen_string_literal: true

require File.expand_path('../../../test_helper', File.dirname(__dir__))
require File.expand_path('../../../with_webdav_settings', File.dirname(__dir__))

module RedmineDrawio
  ##
  # The DMSF WebDAV endpoint is served by a Rack middleware that only accepts
  # HTTP Basic and Digest authentication. The editor has neither a password nor
  # the API key to send, so the token has to be accepted there.
  class DmsfWebdavControllerPatchTest < ActiveSupport::TestCase
    fixtures :users, :email_addresses, :roles

    def setup
      skip 'DMSF is not installed' unless Redmine::Plugin.installed?(:redmine_dmsf)

      User.current = nil
    end

    def teardown
      User.current = nil
    end

    def test_should_authenticate_a_request_carrying_a_valid_token
      with_webdav_settings do
        user = admin

        assert authenticated?(ApiToken.issue(user))
        assert_equal user, User.current
        assert_equal '127.0.0.1', User.current.remote_ip
      end
    end

    def test_should_not_authenticate_a_request_without_token
      with_webdav_settings do
        assert_not authenticated?(nil)
        assert_not_equal admin, User.current
      end
    end

    def test_should_not_authenticate_a_request_carrying_an_invalid_token
      with_webdav_settings do
        assert_not authenticated?('a token nobody can have signed')
        assert_not_equal admin, User.current
      end
    end

    def test_should_not_authenticate_a_request_carrying_an_expired_token
      token = ApiToken.issue(admin)

      travel(2 * ApiToken::TTL) { with_webdav_settings { assert_not authenticated?(token) } }
    end

    def test_should_not_authenticate_a_request_carrying_a_token_of_a_locked_user
      token = ApiToken.issue(admin)
      User.find_by_login!('admin').update_column(:status, User::STATUS_LOCKED)

      with_webdav_settings { assert_not authenticated?(token) }
    end

    private

    def admin
      @admin ||= User.find_by_login!('admin')
    end

    # The middleware renders 401 on false, an exception in Digest mode. Both
    # mean the same thing here: not authenticated.
    #
    # DMSF 3.x (up to Redmine 5) enters authentication through #authenticate,
    # the following versions through #authenticate?.
    def authenticated?(token)
      controller = build_controller(token)
      result = controller.respond_to?(:authenticate?) ? controller.authenticate? : controller.authenticate

      !!result
    rescue Dav4rack::HttpStatus::Unauthorized
      false
    end

    def build_controller(token)
      env = Rack::MockRequest.env_for(
        'https://example.net/dmsf/webdav/%5Becookbook%5D',
        'REQUEST_METHOD' => 'PUT',
        'REMOTE_ADDR' => '127.0.0.1'
      )
      env[token_header] = token if token

      RedmineDmsf::Webdav::DmsfController.new(
        Dav4rack::Request.new(env),
        Rack::Response.new,
        root_uri_path: '/dmsf/webdav',
        resource_class: RedmineDmsf::Webdav::ResourceProxy
      )
    end

    def token_header
      "HTTP_#{ApiToken::HEADER.upcase.tr('-', '_')}"
    end
  end
end