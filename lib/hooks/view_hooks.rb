module RedmineDrawio

  class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      
    def view_layouts_base_html_head(context={})
      if context[:controller] && (context[:controller].is_a?(IssuesController) ||
                                  context[:controller].is_a?(WikiController))
        return stylesheet_link_tag("drawioEditor.css"  , :plugin => "redmine_drawio", :media => "screen")
      else
        return ''
      end
    end
      
    def view_layouts_base_body_bottom(context={})
      if context[:controller] && (context[:controller].is_a?(IssuesController) ||
                                  context[:controller].is_a?(WikiController))
          return javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
      else
        return ''
      end
    end
  end

end

