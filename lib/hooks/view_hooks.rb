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
          return "<script type=\"text/javascript\">var REDMINE_URL = '#{redmine_url(context)}';</script>" +
                 javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
      else
        return ''
      end
    end
    
    private
    
    # Returns the context path of Redmine installation (usually '/' or '/redmine/').
    # Borrowed from plugin favorite_locations
    def redmine_url(context)
        url_for controller: 'welcome'
    end
  end

end

