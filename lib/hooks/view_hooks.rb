module RedmineDrawio
  class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context={})
      if context[:controller] && (context[:controller].is_a?(IssuesController) ||
                                  context[:controller].is_a?(WikiController))
        return javascript_tag(nil, src: "https://www.draw.io/embed2.js?s=er")
      else
        return ''
      end
    end
  end
end
