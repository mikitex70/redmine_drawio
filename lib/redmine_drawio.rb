# encoding: UTF-8

# Drawio libraries

# Patches
require File.expand_path('../redmine_drawio/patches/string_patch', __FILE__)
require File.expand_path('../redmine_drawio/patches/rbpdf_patch', __FILE__)
require File.expand_path('../redmine_drawio/patches/user_preference_patch', __FILE__)

# Helpers
require File.expand_path('../redmine_drawio/helpers/common_mark_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/drawio_dmsf_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/textile_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/markdown_helper', __FILE__) if Redmine::VERSION::MAJOR < 6

# Hooks
require File.expand_path('../redmine_drawio/hooks/view_hooks', __FILE__)
require File.expand_path('../redmine_drawio/hooks/macro_dialog', __FILE__)

# Macros
require File.expand_path('../redmine_drawio/macros', __FILE__)

module RedmineDrawio
  include Redmine::I18n

  # @see https://www.drawio.com/blog/diagram-editor-theme.
  def self.drawio_ui_options_for_select
    [[l(:label_drawio_ui_default), 'kennedy'],
     [l(:label_drawio_ui_atlas), 'atlas'],
     [l(:label_drawio_ui_simple), 'simple'],
     [l(:label_drawio_ui_minimal), 'min'],
     [l(:label_drawio_ui_sketch), 'sketch']]
  end
end
