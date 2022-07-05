# encoding: UTF-8

# Drawio libraries

# Patches
require File.expand_path('../redmine_drawio/patches/string_patch', __FILE__)
require File.expand_path('../redmine_drawio/patches/rbpdf_patch', __FILE__)

# Helpers
require File.expand_path('../redmine_drawio/helpers/drawio_dmsf_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/drawio_settings_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/textile_helper', __FILE__)
require File.expand_path('../redmine_drawio/helpers/markdown_helper', __FILE__)

# Hooks
require File.expand_path('../redmine_drawio/hooks/view_hooks', __FILE__)
require File.expand_path('../redmine_drawio/hooks/macro_dialog', __FILE__)

# Macros
require File.expand_path('../redmine_drawio/macros', __FILE__)


module RedmineDrawio
end
