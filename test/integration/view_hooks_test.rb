# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('authenticate_user', File.dirname(__dir__))
require File.expand_path('load_fixtures', File.dirname(__dir__))
require File.expand_path('with_drawio_settings', File.dirname(__dir__))

class ViewHooksTest < ActionDispatch::IntegrationTest
  include Redmine::I18n
  include RedmineDrawio::AuthenticateUser
  include RedmineDrawio::LoadFixtures
  include RedmineDrawio::WithDrawioSettings

  fixtures :users, :email_addresses, :roles

  def teardown
    Setting.rest_api_enabled = nil
  end

  test 'render warning_api_needs_to_be_enabled when api is disabled' do
    render_view_hooks
    assert_select '#flash_warning', text: l(:drawio_warning_api_needs_to_be_enabled)
  end

  test 'do not render warning_api_needs_to_be_enabled when api is enabled' do
    render_view_hooks(rest_api_enabled: '1')
    assert_select '#flash_warning', 0
  end

  private

  def render_view_hooks(rest_api_enabled: '0')
    Setting.rest_api_enabled = rest_api_enabled
    log_user('admin', 'admin')
    get '/'
    assert_response :success
  end
end
