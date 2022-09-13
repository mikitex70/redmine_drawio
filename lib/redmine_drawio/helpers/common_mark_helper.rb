# encoding: utf-8
require 'redmine'

if Redmine::VERSION::MAJOR >= 5
    # CommonMark is available only from Redmine 5
    module RedmineDrawio
        module Helpers
            module CommonMarkHelper
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
    
    module Redmine::WikiFormatting::CommonMark::Helper
        prepend RedmineDrawio::Helpers::CommonMarkHelper
    end
end
