# frozen_string_literal: true

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('authenticate_user', File.dirname(__dir__))

module RedmineDrawio
  ##
  # The token rendered in the page has to be accepted by the Redmine REST API,
  # which is what the browser uses to save a diagram.
  class ApiTokenAuthenticationTest < ActionDispatch::IntegrationTest
    include RedmineDrawio::AuthenticateUser

    fixtures :users, :email_addresses, :roles

    EDITOR_PAGE = '/projects/ecookbook/issues'
    # Description of issue 1 in the Redmine fixtures
    ORIGINAL_DESCRIPTION = 'Unable to print recipes'

    def setup
      Setting.rest_api_enabled = '1'
    end

    def teardown
      Setting.rest_api_enabled = nil
      User.current = nil
    end

    test 'the token of the page authenticates the requests of the editor' do
      token = page_token(EDITOR_PAGE)

      # This is the request the editor sends to upload the diagram
      upload(token)

      assert_response :created
      assert_kind_of Hash, ActiveSupport::JSON.decode(@response.body)['upload']
    end

    test 'the token of the page is accepted wherever the api key is' do
      token = page_token(EDITOR_PAGE)

      # Rewriting the issue is what the editor does once the attachment is uploaded
      update_issue(1, "Diagram: #{token}", token)

      assert_response :no_content
      assert_equal "Diagram: #{token}", Issue.find(1).reload.description
    end

    test 'a request without token is not authenticated' do
      page_token(EDITOR_PAGE)

      assert_no_difference 'Issue.count' do
        create_issue
        assert_response :unauthorized
      end

      update_issue(1, 'Diagram', nil)

      assert_equal ORIGINAL_DESCRIPTION, Issue.find(1).reload.description
    end

    test 'a request with an invalid token is not authenticated' do
      page_token(EDITOR_PAGE)

      assert_no_difference 'Issue.count' do
        create_issue('a token nobody can have signed')
        assert_response :unauthorized
      end

      update_issue(1, 'Diagram', 'a token nobody can have signed')

      assert_equal ORIGINAL_DESCRIPTION, Issue.find(1).reload.description
    end

    test 'a request with a token is not authenticated when the rest api is disabled' do
      token = page_token(EDITOR_PAGE)
      Setting.rest_api_enabled = '0'

      assert_no_difference 'Issue.count' do
        create_issue(token)
        assert_response :forbidden
      end

      update_issue(1, 'Diagram', token)

      assert_equal ORIGINAL_DESCRIPTION, Issue.find(1).reload.description
    end

    test 'the api key is not sent to the browser' do
      token = page_token(EDITOR_PAGE)

      assert_predicate token, :present?
      assert_not_includes @response.body, admin.api_key
    end

    test 'the header sent by the editor is the one accepted by the server' do
      editor = File.read(File.expand_path('../assets/javascripts/drawioEditor.js', File.dirname(__dir__)))

      assert_includes editor, RedmineDrawio::ApiToken::HEADER
    end

    private

    def admin
      @admin ||= User.find_by_login!('admin')
    end

    # Logs in, renders the given page and returns the token the editor will send
    def page_token(path)
      log_user('admin', 'admin')
      get path
      assert_response :success

      token = @response.body[/hashCode\s*:\s*'([^']*)'/, 1]
      assert_predicate token, :present?, 'the page does not carry a token'
      token
    end

    def upload(token)
      headers = {
        'RAW_POST_DATA' => 'Drawio data',
        'CONTENT_TYPE' => 'application/octet-stream'
      }.merge(token_headers(token))

      post('/uploads.json', headers: headers)
    end

    def update_issue(id, description, token)
      put(
        "/issues/#{id}.json",
        params: { issue: { description: description } },
        headers: token_headers(token)
      )
    end

    # Creating an issue is not allowed for the anonymous user, so this endpoint
    # tells an authenticated request from an unauthenticated one.
    def create_issue(token = nil)
      post(
        '/issues.json',
        params: { issue: { project_id: 1, subject: 'Drawio diagram' } },
        headers: token_headers(token)
      )
    end

    def token_headers(token)
      return {} if token.nil?

      { RedmineDrawio::ApiToken::HEADER => token }
    end
  end
end