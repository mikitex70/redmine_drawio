module RedmineDrawio
  class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
 
    # Script moved into the macro and loaded only if the drawio macro is used.
    # In this manner the the page loading is much faster.
#    def view_layouts_base_body_bottom(context={})
#      if context[:controller] && (context[:controller].is_a?(IssuesController) ||
#                                  context[:controller].is_a?(WikiController))
#        return javascript_tag(nil, src: "https://www.draw.io/embed2.js?s=general;flowchart;bpmn;lean_mapping;electrical;pid;rack;ios;aws2;azure;cisco;clipart;signs;uml;er;mockups")
#      else
#        return ''
#      end
#    end
    
    def view_layouts_base_html_head(context={})
        return stylesheet_link_tag("drawioEditor.css"  , :plugin => "redmine_drawio", :media => "screen") +
               javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
    end
  end
end

