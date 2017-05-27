# encoding: UTF-8

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
                inlineScript = <<-EOF
                    <script type=\"text/javascript\">
                      var REDMINE_URL = '#{redmine_url(context)}',
                      DRAWIO_URL = '#{Setting.plugin_redmine_drawio['drawio_service_url']}',
                      DMSF = #{if Redmine::Plugin.installed?(:redmine_dmsf) &&
                               context[:project].module_enabled?('dmsf') then true else false end};</script>
                EOF
                inlineScript += javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
                inlineScript += javascript_include_tag("drawio_jstoolbar.js", :plugin => "redmine_drawio") unless ckeditor_enabled?
                return inlineScript
            else
                return ''
        end
    end
    
    private
    
    # Returns the context path of Redmine installation (usually '/' or '/redmine/').
    def redmine_url(context)
        rootUrl = ActionController::Base.relative_url_root

        return rootUrl+'/' if rootUrl != nil

        return '/'
    end
    
    def ckeditor_enabled?
        Setting.text_formatting == "CKEditor"
    end
  end

end

