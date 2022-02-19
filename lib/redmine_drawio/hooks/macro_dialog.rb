# encoding: UTF-8

class RedmineDrawioHookListener < Redmine::Hook::ViewListener
    include DrawioSettingsHelper

    def view_layouts_base_body_bottom(context = {})
        html = context[:controller].send(:render_to_string,
                                         { partial: 'redmine_drawio/macro_dialog',
                                           locals: { svg_enabled: svg_enabled? } })
        html.html_safe
    end
end
