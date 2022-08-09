# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('authenticate_user', File.dirname(__dir__))
require File.expand_path('load_fixtures', File.dirname(__dir__))
require File.expand_path('with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class ViewHooksTest < ActionDispatch::IntegrationTest
    include Redmine::I18n
    include RedmineDrawio::AuthenticateUser
    include RedmineDrawio::LoadFixtures
    include RedmineDrawio::WithDrawioSettings

    fixtures :users, :email_addresses, :roles

    def setup
      @view_hooks = RedmineDrawio::Hooks::ViewHooks.instance
    end

    def teardown
      Setting.rest_api_enabled = nil
    end

    test 'render warning_api_needs_to_be_enabled when api is disabled' do
      render_view_hooks(user: 'admin', password: 'admin')
      assert_select '#flash_warning', text: l(:drawio_warning_api_needs_to_be_enabled)
    end

    test 'do not render warning_api_needs_to_be_enabled when api is enabled' do
      render_view_hooks(user: 'admin', password: 'admin', rest_api_enabled: '1')
      assert_select '#flash_warning', 0
    end

    test 'do not render warning_api_needs_to_be_enabled for non admin user' do
      render_view_hooks(user: 'jsmith', password: 'jsmith', rest_api_enabled: '1')
      assert_select '#flash_warning', 0
    end

    test 'do not render hash code when api is disabled' do
      render_view_hooks(user: 'admin', password: 'admin')
      assert @view_hooks.send(:hash_code).blank?
    end

    test 'render hash code when api is enabled' do
      render_view_hooks(user: 'admin', password: 'admin', rest_api_enabled: '1')
      assert @view_hooks.send(:hash_code).present?
    end

    private

    def render_view_hooks(user:, password:, rest_api_enabled: '0')
      Setting.rest_api_enabled = rest_api_enabled
      log_user(user, password)
      get '/'
      assert_response :success
    end
  end
end
