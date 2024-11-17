# frozen_string_literal: true

# Copyright (C) 2024 Liane Hampe <liaham@xmera.de>, xmera.

require File.expand_path('../../../test_helper', File.dirname(__dir__))
require File.expand_path('../../../with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class UserPreferencePatchTest < ActiveSupport::TestCase
    fixtures :users, :user_preferences

    def setup
      User.current = nil
    end

    def test_should_respond_to_drawio_ui
      preference = UserPreference.new
      assert preference.respond_to?(:drawio_ui)
      assert preference.respond_to?(:drawio_ui=)
    end

    def test_should_respond_to_drawio_ui_valid
      preference = UserPreference.new
      assert preference.respond_to?(:drawio_ui_valid?)
    end

    def test_should_return_default_drawio_ui_when_unset
      preference = UserPreference.new
      assert_equal 'kennedy', preference.drawio_ui
    end

    def test_should_return_default_drawio_ui_with_invalid_values
      preference = UserPreference.new
      preference.drawio_ui = 'invalid'
      assert_equal 'kennedy', preference.drawio_ui
    end

    def test_should_set_drawio_ui
      preference = UserPreference.new
      preference.drawio_ui = 'atlas'
      assert_equal 'atlas', preference.drawio_ui

      preference.drawio_ui = 'simple'
      assert_equal 'simple', preference.drawio_ui

      preference.drawio_ui = 'min'
      assert_equal 'min', preference.drawio_ui

      preference.drawio_ui = 'sketch'
      assert_equal 'sketch', preference.drawio_ui
    end
  end
end
