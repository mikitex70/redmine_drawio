# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

module RedmineDrawio
  module WithDrawioSettings
    def redmine_drawio(**attrs)
      { plugin_redmine_drawio: attrs }.with_indifferent_access
    end
  end
end
