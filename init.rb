# encoding: utf-8

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Michele Tessaro'
  description 'Wiki macro plugin for inserting drawio diagrams into Wiki pages and Issues'
  version '0.8.0'
  url 'https://github.com/mikitex70/redmine_drawio'
  author_url 'https://github.com/mikitex70'

  requires_redmine version: '2.6'..'3.4'

  settings(partial: 'settings/drawio_settings',
           default: {'drawio_service_url' => '//www.draw.io',
                     'drawio_mathjax'     => false })

  should_be_disabled false if Redmine::Plugin.installed?(:easy_extensions)
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
