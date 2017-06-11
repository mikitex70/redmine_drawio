# encoding: utf-8
require 'redmine'

module Redmine::WikiFormatting::Textile::Helper
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
    
    alias_method_chain :heads_for_wiki_formatter, :drawio
end
