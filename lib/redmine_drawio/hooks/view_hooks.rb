# encoding: UTF-8
require 'base64'

module RedmineDrawio

    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener

        def view_layouts_base_body_bottom(context={})
            drawio_scripts context
        end
        
        def view_issues_show_description_bottom(context={})
            drawio_scripts context
        end
        
        def view_journals_notes_form_after_notes(context={})
            drawio_scripts context
        end
        
        private
        
        def drawio_scripts(context)
            if context[:controller] && editable?(context)
                header = <<-EOF
                    <script type=\"text/javascript\">
                        var Drawio = {
                            settings: {
                                redmineUrl: '#{redmine_url(context)}',
                                hashCode: '#{Base64.encode64(User.current.api_key).reverse!.gsub(/\n/, '\\\\\n')}',
                                drawioUrl: '#{Setting.plugin_redmine_drawio['drawio_service_url']}',
                                DMSF: #{dmsf_enabled? context}
                            }
                        };</script>
                EOF
                
                header << stylesheet_link_tag("drawioEditor.css"  , :plugin => "redmine_drawio", :media => "screen")
                header << javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("lang/drawio_jstoolbar-en.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("lang/drawio_jstoolbar-#{current_language.to_s.downcase}.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("drawio_jstoolbar.js", :plugin => "redmine_drawio") unless ckeditor_enabled?
                
                return header
            else
                return ''
        end
        
    end
    
    private
    
    def editable?(context)
        return true if context[:controller].is_a?(WikiController) && User.current.allowed_to?(:edit_wiki_pages, context[:project])
        return false unless context[:controller].is_a?(IssuesController)
        
        if context[:issue].nil?
            return false if context[:journal].nil?
            
            context[:journal].editable_by?(User.current)
        else
            context[:issue].editable?(User.current)
        end
    end
    
    # Returns the context path of Redmine installation (usually '/' or '/redmine/').
    def redmine_url(context)
        rootUrl = ActionController::Base.relative_url_root

        return rootUrl+'/' if rootUrl != nil

        return '/'
    end
    
    def dmsf_enabled?(context)
        return false unless Redmine::Plugin.installed? :redmine_dmsf
        return false unless context[:project].module_enabled?('dmsf')
        true
    end
    
    def ckeditor_enabled?
        Setting.text_formatting == "CKEditor"
    end
  end

end

