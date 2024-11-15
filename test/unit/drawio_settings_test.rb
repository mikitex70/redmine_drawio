# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class DrawioSettingsTest < ActiveSupport::TestCase
    include RedmineDrawio::WithDrawioSettings

    def teardown
      Setting.plugin_redmine_drawio = { drawio_svg_enabled: nil,
                                        drawio_service_url: nil }
      Setting.clear_cache
    end

    def test_svg_disabled
      with_settings(redmine_drawio(**{ drawio_svg_enabled: false })) do
        assert_not DrawioSettings.svg_enabled?
      end
    end

    def test_svg_enabled
      with_settings(redmine_drawio(**{ drawio_svg_enabled: true })) do
        assert DrawioSettings.svg_enabled?
      end
    end

    def test_default_drawio_service_url
      assert_equal '//embed.diagrams.net', DrawioSettings.drawio_url
    end

    def test_custom_drawio_service_url
      with_settings(redmine_drawio(**{ drawio_service_url: '//custom' })) do
        assert_equal '//custom', DrawioSettings.drawio_url
      end
    end
  end
end
