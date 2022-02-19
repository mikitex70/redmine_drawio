# frozen_string_literal: true

# Copyright (C) 2022 Liane Hampe <liaham@xmera.de>, xmera.

module RedmineDrawio
  ##
  # Redmine won't load plugin fixtures out-of-the-box.
  # This module loads first the plugin fixtures and then Redmine fixtures
  # if the listed file does not exist in the plugin's fixture directory.
  #
  module LoadFixtures
    class << self
      def fixtures(*table_names)
        dir = File.join(File.dirname(__FILE__), '/fixtures')
        table_names.each do |file|
          create_fixtures(dir, file) if File.exist?("#{dir}/#{file}.yml")
        end
        super(table_names)
      end

      private

      def create_fixtures(dir, file)
        ActiveRecord::FixtureSet.create_fixtures(dir, file)
      end
    end
  end
end
