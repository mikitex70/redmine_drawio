# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('authenticate_user', File.dirname(__dir__))
require File.expand_path('load_fixtures', File.dirname(__dir__))
require File.expand_path('with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class MacroDialogTest < ActionDispatch::IntegrationTest
    include RedmineDrawio::AuthenticateUser
    include RedmineDrawio::LoadFixtures
    include RedmineDrawio::WithDrawioSettings

    fixtures :users, :email_addresses, :roles

    def teardown
      Setting.plugin_redmine_drawio = { drawio_svg_enabled: nil }
    end

    test 'render macro dialog' do
      render_marcro_dialog
      assert_select '#dlg_redmine_drawio'
    end

    test 'render macro diaglog without svg' do
      with_settings(redmine_drawio({ drawio_svg_enabled: false })) do
        render_marcro_dialog
        assert_select 'input[value=?]', 'svg', 0
      end
    end

    test 'render macro diaglog with svg' do
      with_settings(redmine_drawio({ drawio_svg_enabled: true })) do
        render_marcro_dialog
        assert_select 'input[value=?]', 'svg'
      end
    end

    private

    def render_marcro_dialog
      log_user('admin', 'admin')
      get '/settings/plugin/redmine_drawio'
      assert_response :success
    end
  end
end
