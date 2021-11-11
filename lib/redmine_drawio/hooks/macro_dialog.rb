# encoding: UTF-8

class RedmineDrawioHookListener < Redmine::Hook::ViewListener
    svg_enabled = Setting[:plugin_redmine_drawio]['drawio_svg_enabled']
    svg_enabled = true if svg_enabled.nil?
    
    render_on :view_layouts_base_body_bottom, :partial => "redmine_drawio/macro_dialog", :locals => {
        svg_enabled: svg_enabled
    }
end
