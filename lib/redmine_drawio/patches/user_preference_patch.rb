# frozen_string_literal: true

module RedmineDrawio
  module Patches
    # Supports custom Drawio UI settings
    module UserPreferencePatch
      UserPreference.safe_attributes 'drawio_ui'

      def drawio_ui
        self[:drawio_ui] || 'kennedy'
      end

      def drawio_ui=(value)
        self[:drawio_ui] = drawio_ui_valid?(value) ? value : 'kennedy'
      end

      def drawio_ui_valid?(value)
        RedmineDrawio.drawio_ui_options_for_select.map(&:last).include?(value.to_s)
      end
    end
  end
end

UserPreference.prepend RedmineDrawio::Patches::UserPreferencePatch
