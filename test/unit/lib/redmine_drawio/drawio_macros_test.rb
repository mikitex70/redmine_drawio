# frozen_string_literal: true

# Copyright (C) 2023 Liane Hampe <liaham@xmera.de>, xmera Solutions GmbH.

require File.expand_path('../../test_helper', File.dirname(__dir__))
require File.expand_path('../../with_drawio_settings', File.dirname(__dir__))

module RedmineDrawio
  class DrawioMacrosTest < ActiveSupport::TestCase
    include RedmineDrawio::WithDrawioSettings
    include ApplicationHelper
    include ActionView::Helpers
    include ActionDispatch::Routing
    include ERB::Util
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper

    fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
             :groups_users,
             :trackers, :projects_trackers,
             :enabled_modules,
             :versions,
             :issue_statuses, :issue_categories, :issue_relations, :workflows,
             :enumerations,
             :issues, :journals, :journal_details,
             :watchers,
             :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values,
             :time_entries

    def setup 
      @jsmith = User.find 2
      @manager_role = Role.find_by(name: 'Manager')
      @manager_role.add_permission! :view_dmsf_files
      @project1 = Project.find 1
      @project1.enable_module! :wiki

      User.current = @jsmith
      default_url_options[:host] = 'http://example.com'
    end

    def test_macro_drawio_deprecated 
      text = textilizable("{{drawio(new-drawing.xml, hilight=#0000ff)}}")
      assert_equal "<p>«The drawio macro is deprecated, use the drawio_attach macro instead»</p>", text 
    end

    def test_macro_drawio_attach_unsaved
      text = textilizable("{{drawio_attach(new-drawing.xml, hilight=#0000ff)}}")
      assert_equal "<p>«Please save content first»</p>", text
    end

    def test_macro_drawio_dmsf_unsaved
      text = textilizable("{{drawio_dmsf(new-drawing.xml, hilight=#0000ff)}}")
      assert_equal "<p>«Please save content first»</p>", text
    end

    def test_macro_drawio_dmsf_with_existing_document
      return unless Redmine::Plugin.installed?(:redmine_dmsf)

      file_name = 'test.xml'
      prepare_dmsf_module(file_name)
      
      assert_nothing_raised do
        result = exec_macro('drawio_dmsf', @obj, file_name, nil, hilight: '#0000ff')
        assert result.match(file_name), "Macro result does not match #{file_name}!"
      end

      FileUtils.rm_rf DmsfFile.storage_path
      rescue StandardError => e
        puts e.message
      ensure 
        Setting.clear_cache
    end

    private

    def prepare_dmsf_module(file_name)      
      @project1.enable_module! :dmsf
      Setting.plugin_redmine_dmsf['dmsf_storage_directory'] = File.join('files', ['dmsf'])
      FileUtils.cp_r File.join(File.expand_path('../../../../fixtures/files', __FILE__), '.'), DmsfFile.storage_path
      year = Date.today.year
      month = Date.today.month
      FileUtils.mkdir_p File.join(DmsfFile.storage_path, "#{year}/#{month}")
      FileUtils.mv File.join(DmsfFile.storage_path, file_name), File.join(DmsfFile.storage_path, "#{year}/#{month}", file_name)
      file = DmsfFile.create!(project_id: 1, name: file_name)
      revision = DmsfFileRevision.create!(dmsf_file_id: file.id, name: file_name, disk_filename: file_name, user_id: @jsmith.id, title: 'Drawio test file', major_version: 1)
      @obj = Issue.create!(project_id: 1, subject: 'Issue with drawio', status_id: 1, tracker_id: 1, author_id: @jsmith.id)
    end
  end
end
