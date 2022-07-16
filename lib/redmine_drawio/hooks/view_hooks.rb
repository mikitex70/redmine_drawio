# encoding: UTF-8
require 'redmine'
require 'base64'

module RedmineDrawio
    module Hooks
        class ViewLayoutsBaseBodyTop < Redmine::Hook::ViewListener
            def view_layouts_base_body_top(context = {})
                return unless User.current.admin? && !Setting.rest_api_enabled?

                context[:controller].send(:render_to_string, { partial: 'redmine_drawio/hooks/api_not_enabled_warning' })
            end
        end

        class ViewHooks < Redmine::Hook::ViewListener
            
            # This method will add the necessary CSS and JS scripts to the page header.
            # The scripts are loaded before the 'jstoolbar-textile.min.js' is loaded so
            # the toolbar cannot be patched.
            # A second step is required: the textile_helper.rb inserts a small Javascript
            # fragment after the jstoolbar-textile is loaded, which pathes the jsToolBar
            # object.
            def view_layouts_base_html_head(context={})
                if Setting.plugin_redmine_drawio['drawio_service_url'].to_s.strip.empty?
                  viewer_url = 'https://viewer.diagrams.net'
                else
                  viewer_url = Setting.plugin_redmine_drawio['drawio_service_url']
                end
                # loading XML viewer library, only if necessary
                header = <<-EOF
                    <script type="text/javascript">//<![CDATA[
                        $(function() {
                            if($(".mxgraph").length) {
                                var script = document.createElement('script');
                                script.src = '#{viewer_url}/js/viewer-static.min.js';
                                document.head.append(script);
                            }
                        });
                    //]]</script>
                EOF
                
                if Setting.plugin_redmine_drawio['drawio_mathjax']
                    # Some MathJax tuning:
                    # * set regexp for classes to ignore, for to no apply MathJax to wrong elements
                    # * MathJax context menu (enabled, maybe is better to disable it?)
                    inline = <<-EOF
                    <script type="text/x-mathjax-config">//<![CDATA[
                    MathJax.Hub.Config({
                        /*menuSettings: {
                        context: "Browser"
                        },*/
                        tex2jax: {
                        //inlineMath: [['$', '$'], ['\\(', '\\)']],
                        ignoreClass: "no-mathjax|error|warning|notice"
                        },
                        asciimath2jax: {
                        ignoreClass: "no-mathjax|error|warning|notice"
                        }
                    });
                    //]]</script>
                    EOF
                    header << inline
                    header << javascript_include_tag("#{mathjax_url}?config=TeX-MML-AM_HTMLorMML")
                end
                
                return header unless editable?(context)
                
                if Setting.plugin_redmine_drawio['drawio_service_url'].to_s.strip.empty?
                    drawio_url = '//embed.diagrams.net'
                else
                    drawio_url = Setting.plugin_redmine_drawio['drawio_service_url']
                end
                
                inline = <<-EOF
                    <script type=\"text/javascript\">//<![CDATA[
                        var Drawio = {
                        settings: {
                            redmineUrl: '#{redmine_url}',
                            hashCode  : '#{hash_code}',
                            drawioUrl : '#{drawio_url}',
                            DMSF      : #{dmsf_enabled? context},
                            isEasyRedmine: #{easyredmine?}
                        }
                        };
                    //]]></script>
                EOF
                
                header << inline
                header << stylesheet_link_tag("drawioEditor.css"  , :plugin => "redmine_drawio", :media => "screen")
                header << javascript_include_tag("encoding-indexes.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("encoding.min.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("drawioEditor.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("lang/drawio_jstoolbar-en.js", :plugin => "redmine_drawio")
                header << javascript_include_tag("lang/drawio_jstoolbar-#{current_language.to_s.downcase}.js", :plugin => "redmine_drawio") if lang_supported? current_language.to_s.downcase
                header << javascript_include_tag("drawio_jstoolbar.js", :plugin => "redmine_drawio") unless ckeditor_enabled?
                header
            end
            
            private
            
            def editable?(context)
                return false unless context[:controller]
                return true  if context[:controller].is_a?(WikiController) && User.current.allowed_to?(:edit_wiki_pages, context[:project])
                return false unless context[:controller].is_a?(IssuesController)

                if context[:issue].nil?
                    return true if context[:journal].nil?
                    context[:journal].editable_by?(User.current)
                else
                    context[:issue].editable?(User.current)
                end
            end
            
            # Returns the context path of Redmine installation (usually '/' or '/redmine/').
            def redmine_url
                rootUrl = ActionController::Base.relative_url_root

                return rootUrl+'/' if rootUrl != nil

                return '/'
            end
            
            def dmsf_enabled?(context)
                return false unless Redmine::Plugin.installed? :redmine_dmsf
                return false unless context[:project] && context[:project].module_enabled?('dmsf')
                true
            end
            
            def ckeditor_enabled?
                Setting.text_formatting == "CKEditor"
            end
            
            def easyredmine?
                Redmine::Plugin.installed?(:easy_redmine)
            end
            
            def lang_supported? lang
                return false if lang == 'en' # English is always loaded, avoid double load
                File.exist? "#{File.expand_path('../../../../assets/javascripts/lang', __FILE__)}/drawio_jstoolbar-#{lang}.js"
            end
            
            def mathjax_url
                url = Setting.plugin_redmine_drawio['drawio_mathjax_url']
                url = '//cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js' unless url.present?
                url
            end

            def hash_code
                return '' unless Setting.rest_api_enabled?

                Base64.encode64(User.current.api_key).gsub(/\n/, '').reverse!
            end
        end
    end
end
