# frozen_string_literal: true

module RedmineDrawio
  module WithWebdavSettings
    def with_webdav_settings
      # The cache is dropped before, assigning to the memoized plugin settings
      # hash is what Redmine itself does, clearing afterwards would drop it
      Setting.clear_cache
      Setting.plugin_redmine_dmsf['dmsf_webdav'] = 1

      yield
    ensure
      Setting.clear_cache
    end
  end
end

ActiveSupport::TestCase.include(RedmineDrawio::WithWebdavSettings)
