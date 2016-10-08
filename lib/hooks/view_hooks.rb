module RedmineDrawio
  class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      
    def view_layouts_base_body_bottom(context={})
      if context[:controller] && (context[:controller].is_a?(IssuesController) ||
                                  context[:controller].is_a?(WikiController))
        return javascript_tag(nil, src: "https://www.draw.io/embed2.js?s=general;flowchart;bpmn;lean_mapping;electrical;pid;rack;ios;aws2;azure;cisco;clipart;signs;uml;er;mockups")
      else
        return ''
      end
    end
  end
end

