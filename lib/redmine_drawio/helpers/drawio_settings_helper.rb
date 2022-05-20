# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

##
# Helps to use the plugin settings throughout the code.
#
# @note The table check is necessary for running tests since the table is not
#   available when loading this code first.
#
module RedmineDrawio
    module Helpers
        module DrawioSettingsHelper
            def self.svg_enabled?
                return false unless ActiveRecord::Base.connection.data_source_exists? 'settings'

                Setting[:plugin_redmine_drawio]['drawio_svg_enabled'].present? ? true : false
            end
        end
    end
end
