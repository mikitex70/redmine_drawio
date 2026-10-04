# frozen_string_literal: true

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('authenticate_user', File.dirname(__dir__))
require File.expand_path('with_webdav_settings', File.dirname(__dir__))

module RedmineDrawio
  ##
  # The editor saves DMSF documents with a PUT to /dmsf/webdav. That endpoint is
  # a Rack middleware, so the token has to be accepted by the DMSF controller
  # and not by ApplicationController as it happens for the REST API.
  #
  # Only the authentication outcome is checked here: what the DMSF resource
  # layer answers afterwards depends on the content of the project, and 401 can
  # only come from #authenticate?.
  class DmsfWebdavAuthenticationTest < ActionDispatch::IntegrationTest
    include RedmineDrawio::AuthenticateUser
    fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules

    EDITOR_PAGE = '/projects/ecookbook/issues'
    DMSF_ROOT = '/dmsf/webdav/%5Becookbook%5D'
    DMSF_FILE = "#{DMSF_ROOT}/drawio_test_file.drawio"

    def setup
      skip 'DMSF is not installed' unless Redmine::Plugin.installed?(:redmine_dmsf)

      Setting.rest_api_enabled = '1'
      available = with_webdav_settings { webdav_available? }
      skip 'the DMSF WebDAV endpoint is not available' unless available
    end

    def teardown
      Setting.clear_cache
    end

    test 'the token of the page authenticates the webdav request of the editor' do
      with_webdav_settings { put_dmsf_file(page_token(EDITOR_PAGE)) }

      assert_not_equal 401, response.status
      assert_not_equal 404, response.status
    end

    test 'a request without token is not authenticated' do
      with_webdav_settings { put_dmsf_file(nil) }

      assert_equal 401, response.status
    end

    test 'a request with an invalid token is not authenticated' do
      with_webdav_settings { put_dmsf_file('a token nobody can have signed') }

      assert_equal 401, response.status
    end

    private

    # The plugin can be installed while its WebDAV endpoint is not served at
    # all, in which case every request is a plain 404
    def webdav_available?
      get DMSF_ROOT

      response.status != 404
    end

    def put_dmsf_file(token)
      headers = { 'CONTENT_TYPE' => 'application/octet-stream' }
      headers['X-Redmine-Drawio-Token'] = token if token

      put DMSF_FILE, params: 'diagram', headers: headers
    end

    def page_token(page)
      log_user('admin', 'admin')
      get page
      assert_response :success

      token = response.body[/hashCode\s*:\s*'([^']*)'/, 1]
      assert_predicate token, :present?, 'the page does not carry a token'

      token
    end
  end
end