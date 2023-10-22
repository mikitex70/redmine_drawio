# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('test_helper', File.dirname(__dir__))
require File.expand_path('with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class DrawioSettingsHelperTest < ActiveSupport::TestCase
    include RedmineDrawio::WithDrawioSettings

    def teardown
      Setting.plugin_redmine_drawio = { drawio_svg_enabled: nil }
      Setting.clear_cache
    end

    def test_svg_disabled
      with_settings(redmine_drawio(**{ drawio_svg_enabled: false })) do
        assert_not svg_enabled?
      end
    end

    def test_svg_enabled
      with_settings(redmine_drawio(**{ drawio_svg_enabled: true })) do
        assert svg_enabled?
      end
    end

    private

    def svg_enabled?
      RedmineDrawio::Helpers::DrawioSettingsHelper.svg_enabled?
    end
  end
end
