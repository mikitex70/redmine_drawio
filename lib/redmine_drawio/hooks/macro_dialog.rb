# encoding: UTF-8

class RedmineDrawioHookListener < Redmine::Hook::ViewListener
    render_on :view_layouts_base_body_bottom, :partial => "redmine_drawio/macro_dialog"
end
