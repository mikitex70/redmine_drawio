# frozen_string_literal: true

# Reads the plugin settings and default values
class DrawioSettings
  class << self
    def drawio_url
      url = self['drawio_service_url']
      url = defaults['drawio_service_url'] unless url.present?
      url
    end

    def svg_enabled?
      [true, 1, 'true', '1'].include?(self['drawio_svg_enabled'])
    end

    def defaults
      @defaults ||= plugin.settings[:default]
    end

    def [](value)
      @values = Setting.plugin_redmine_drawio
      return unless @values

      @values[value.to_s]
    end

    def plugin
      @plugin ||= Redmine::Plugin.find(:redmine_drawio)
    end
  end
end
