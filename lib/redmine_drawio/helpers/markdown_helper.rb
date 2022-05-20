# encoding: utf-8
require 'redmine'

# With Rails 5 there is some problem using the `alias_method`, can generate
# a `stack level too deep` exeception.
if Rails::VERSION::STRING < '5.0.0'
    # Rails 4, the `alias_method` can be used
    module Redmine::WikiFormatting::Markdown::Helper
        def heads_for_wiki_formatter_with_drawio
            heads_for_wiki_formatter_without_drawio
            unless @heads_for_wiki_formatter_with_drawio_included
                # This code is executed only once and inserts a javascript code
                # that patches the jsToolBar adding the new buttons.
                # After that, all editors in the page will get the new buttons.
                content_for :header_tags do
                    javascript_tag 'if(typeof(Drawio) !== "undefined") Drawio.initToolbar();'
                end
                @heads_for_wiki_formatter_with_drawio_included = true
            end
        end
        
        # alias_method_chain is deprecated in Rails 5: replaced with two alias_method
        # as a quick workaround. Using the 'prepend' method can generate an
        # 'stack level too deep' error in conjunction with other (non ported) plugins.
        #alias_method_chain :heads_for_wiki_formatter, :drawio
        alias_method :heads_for_wiki_formatter_without_drawio, :heads_for_wiki_formatter
        alias_method :heads_for_wiki_formatter, :heads_for_wiki_formatter_with_drawio
    end
else
    # Rails 5, use new `prepend` method
    module RedmineDrawio
        module Helpers
            module MarkdownHelper
                def heads_for_wiki_formatter
                    super
                    unless @heads_for_wiki_formatter_with_drawio_included
                        # This code is executed only once and inserts a javascript code
                        # that patches the jsToolBar adding the new buttons.
                        # After that, all editors in the page will get the new buttons.
                        content_for :header_tags do
                            javascript_tag 'if(typeof(Drawio) !== "undefined") Drawio.initToolbar();'
                        end
                        @heads_for_wiki_formatter_with_drawio_included = true
                    end
                end
            end
        end
    end
    
    module Redmine::WikiFormatting::Markdown::Helper
        prepend RedmineDrawio::Helpers::MarkdownHelper
    end
end
