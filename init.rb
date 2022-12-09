# encoding: utf-8

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Michele Tessaro'
  description 'Wiki macro plugin for inserting drawio diagrams into Wiki pages and Issues'
  version '1.4.5'
  url 'https://github.com/mikitex70/redmine_drawio'
  author_url 'https://github.com/mikitex70'

  requires_redmine :version_or_higher => '2.6.0'

  settings(partial: 'settings/drawio_settings',
           default: {'drawio_service_url' => '//embed.diagrams.net',
                     'drawio_mathjax'     => false,
                     'drawio_mathjax_url' => '//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js',
                     'drawio_svg_enabled' => false })

  should_be_disabled false if Redmine::Plugin.installed?(:easy_extensions)
end

unless Redmine::Plugin.installed?(:easy_extensions)
  require_relative 'after_init'
end
