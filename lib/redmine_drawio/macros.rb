# encoding: utf-8
require 'base64'
require 'redmine'
require 'json'

module RedmineDrawio
    module Macros

        Redmine::WikiFormatting::Macros.register do
            desc <<EOF
This macro is deprecated. Use the drawio_attach macro instead.
EOF
    
            macro :drawio do |obj, args|
                return "«The drawio macro is deprecated, use the drawio_attach macro instead»"
            end
        end

        Redmine::WikiFormatting::Macros.register do
            desc <<EOF
Macro for embedding www.draw.io diagrams stored as attachments. Example usage:

{{drawio_attach(myDiagram[, ...options...])}}

The diagram is drawn from the attachment myDiagram.png (diagram esported as png+xml);
if the attachment does not exists a default diagram wil be drawn. Double click it to start
editing.

Supported diagrams format are:
* png: diagram exported as png+xml (embedded source diagram)
* svg: diagram exported as svg+xml (embedded source diagram)
* xml: classic diagram xml source
* drawio: same ax xml

Every time a diagram is saved, a new attachment will be created; for now you must 
manually delete old attachments (missing Redmine API; version 3.3.0 seems to have included
an API to delete attachments but need investigation).

options:
size=number     : forced width of the diagram image, in pixels

options specific for diagrams in XML format:
tbautohide=true : show the toolbar only when the mouse is over the diagram
hilight=#0000ff : color to hilight hyperlinks
layers=false    : enable layer selector (only for multi-layer diagrams)
page=false      : enable page control (only for multi-page diagrams)
zoom=false      : enable zoom controls
lightbox=false  : enable lightbox usage
EOF
    
            macro :drawio_attach do |obj, args|
                return "«Please save content first»" unless obj
                return "«Drawio diagrams are available only in issues and wiki pages»" unless obj.is_a?(WikiContent) or obj.is_a?(Issue) or obj.is_a?(Journal)
                
                args, options = extract_macro_options(args, :size, :hilight, :tbautohide, :lightbox, :zoom, :page, :layers)
                diagramName   = RedmineDrawio::Macros.strip_non_filename_chars(args.first)
                
                return "«Please set a diagram name»".html_safe unless diagramName
                return "«Only png, svg and xml diagram formats are supported»".html_safe unless diagramName =~ /.*(\.(png|svg|xml|drawio))?$/i
                return "svg diagrams are disabled by the administrator" unless RedmineDrawio::Macros.svg_enabled? || not(diagramName =~ /.*\.svg$/i)
                
                # defalts
                hilight    = "#0000ff"
                tbautohide = true
                lightbox   = false
                size       = nil
                page       = 0
                layers     = ''
                zoom       = false
                
                size = options[:size].to_i unless options[:size].blank? or not options[:size][/^\d+$/]
                # parameters checkings
                hilight    = options[:hilight]            unless options[:hilight].blank?
                tbautohide = options[:tbautohide].to_bool unless options[:tbautohide].blank?
                lightbox   = options[:lightbox].to_bool   unless options[:lightbox].blank?
                #size       = options[:fit].to_i           unless options[:fit].blank?
                zoom       = options[:zoom].to_bool       unless options[:zoom].blank?
                page       = options[:page].to_i          unless options[:page].blank?
                layers     = options[:layers]             unless options[:layers].blank?
                
                inlineStyle = ""
                inlineStyle = "width:#{size}px;" if size
                
                if obj.is_a?(WikiContent)
                    container = obj.page
                    title     = container.title
                    canEdit   = User.current.allowed_to?(:edit_wiki_pages, @project)
                elsif obj.is_a?(Journal)
                    container = obj
                    title     = nil  # not necessary
                    canEdit   = container.editable_by?(User.current)
                else
                    container = obj
                    title     = nil  # not necessary
                    canEdit   = container.editable?(User.current)
                end

                # Add an extension, if missing
                diagramName += ".png" if File.extname(diagramName.strip) == ""
                diagramExt  = File.extname(diagramName.strip)
                
                # Search attachment position
                attach = container.attachments.select { |attachment| attachment.filename == diagramName } .last
                
                if canEdit
                    # Diagram and document are editable
                    if Redmine::Plugin.installed?(:easy_redmine)
                        # EasyRedmine can update the attachment without duplications
                        saveName = diagramName
                    else
                        if diagramName =~ /_\d+\./
                            saveName = diagramName.sub(/_(\d+)/) {|v| v.next } # increment version
                        else
                            saveName = diagramName.sub(/(\.\w+)$/, '_1\1') # set version to _1
                        end
                    end
                else
                    # Diagram cannot be saved, it will become not editable
                    saveName = nil
                end
                
                if attach
                    filename = attach.diskfile
                else
                    filename = RedmineDrawio::Macros.imagePath('defaultImage'+diagramExt)
                end

                if attach && RedmineDrawio::Macros.pdf?(self.controller)
                  url = download_named_attachment_url(attach, attach.filename, :only_path => true )
                  return ActionController::Base.helpers.image_tag(url, :style => "#{inlineStyle}")
                end

                diagram = File.read(filename, mode: 'rb')
                
                if RedmineDrawio::Macros.svg? diagramName
                    return RedmineDrawio::Macros.encapsulateSvg(RedmineDrawio::Macros.adaptSvg(diagram, size), inlineStyle, diagramName, title, saveName, false)
                elsif RedmineDrawio::Macros.png? diagramName
                    # if png, encode image and remove newlines (required by Internet Explorer)
                    diagram = Base64.encode64(diagram).gsub("\n", '')
                    return RedmineDrawio::Macros.encapsulatePng(diagram, inlineStyle, diagramName, title, saveName, false)
                else
                    tb = []
                    tb << 'pages'    unless options[:page].blank?
                    tb << 'layers'   unless layers.blank?
                    tb << 'zoom'     if zoom
                    tb << 'lightbox' if lightbox
                    
                    toolbar = if tb.empty? then nil else tb.join(' ') end
                    #style   = if size then 'style="max-width:'+size+'px;"' else "" end

                    # https://desk.draw.io/support/solutions/articles/16000042542-embed-html
                    # https://desk.draw.io/support/solutions/articles/16000042544-embed-mode
                    graphOpts = {
                        'highlight'      => hilight,
                        'nav'            => false,
                        'edit'           => '_blank',
                        'lightbox'       => lightbox,
                        'resize'         => true,
                        'auto-fit'       => true,
                        'editable'       => false,
                        ##'zoom'           => zoom,
                        'page'           => page,
                        'layers'         => if layers == '*' then nil else layers end,
                        'toolbar-nohide' => (not tbautohide),
                        'toolbar'        => toolbar,
                        'xml'            => diagram
                    }
                    return RedmineDrawio::Macros.encapsulateXml(graphOpts, inlineStyle, diagramName, title, saveName, false)
                end
            end
        end

        if Redmine::Plugin.installed?(:redmine_dmsf)
            Redmine::WikiFormatting::Macros.register do
                desc <<EOF
Macro for embedding www.draw.io diagrams stored as DMSF documents. Example usage:

{{drawio_dmsf(myDiagram[, ...options...])}}

The diagram is drawn from the DMSF document myDiagram.png(diagram esported as png+xml);
if the attachment does not exists a default diagram wil be drawn. Double click it to start
editing.

Supported diagrams format are:
* png: diagram exported as png+xml (embedded source diagram)
* svg: diagram exported as svg+xml (embedded source diagram)
* xml: classic diagram xml source
* drawio: same ax xml

The diagram name can contain a path. For example:

{{drawio_dmsf(path/to/folder/myDiagram.svg)}}

will create/edit the document myDiagram.svg in the DMSF folder path/to/folder of
the current project (the folder must exists).

options:
size=number     : forced width of the diagram image, in pixels

options specific for diagrams in XML format:
tbautohide=true : show the toolbar only when the mouse is over the diagram
hilight=#0000ff : color to hilight hyperlinks
layers=false    : enable layer selector (only for multi-layer diagrams)
page=false      : enable page control (only for multi-page diagrams)
zoom=false      : enable zoom controls
lightbox=false  : enable lightbox usage
EOF
        
                macro :drawio_dmsf do |obj, args|
                    return "«Please save content first»" unless obj
                    return "«Drawio diagrams are available only in issues and wiki pages»" unless obj.is_a?(WikiContent) or obj.is_a?(Issue) or obj.is_a?(Journal)
                    
                    args, options = extract_macro_options(args, :size, :hilight, :tbautohide, :lightbox, :zoom, :page, :layers)
                    diagramName   = RedmineDrawio::Macros.strip_non_filename_chars(args.first).force_encoding("UTF-8")
                    
                    return "«Please set a diagram name»".html_safe unless diagramName
                    return "«Only png, svg, xml, and drawio diagram formats are supported»".html_safe unless diagramName =~ /.*(\.(png|svg|xml|drawio))?$/i
                    return "svg diagrams are disabled by the administrator" unless RedmineDrawio::Macros.svg_enabled? || not(diagramName =~ /.*\.svg$/i)
                    
                    # Add an extension, if missing
                    diagramName += ".png" if File.extname(diagramName.strip) == ""
                    diagramExt  = File.extname(diagramName.strip)
                    
                    size = options[:size].to_i unless options[:size].blank? or not options[:size][/^\d+$/]
                    # parameters checkings
                    hilight    = options[:hilight]            unless options[:hilight].blank?
                    tbautohide = options[:tbautohide].to_bool unless options[:tbautohide].blank?
                    lightbox   = options[:lightbox].to_bool   unless options[:lightbox].blank?
                    #size       = options[:fit].to_i           unless options[:fit].blank?
                    zoom       = options[:zoom].to_bool       unless options[:zoom].blank?
                    page       = options[:page].to_i          unless options[:page].blank?
                    layers     = options[:layers]             unless options[:layers].blank?
                    
                    inlineStyle = ""
                    inlineStyle = "width:#{size}px;" if size
                    
                    if obj.is_a?(WikiContent)
                        container = obj.page
                        title     = container.title
                        project   = container.wiki.project
                        canEdit   = User.current.allowed_to?(:edit_wiki_pages, @project)
                    elsif obj.is_a?(Journal)
                        container = obj
                        title     = nil # not necessary
                        project   = container.project
                        canEdit   = container.editable_by?(User.current)
                    else
                        container = obj
                        title     = nil # not necessary
                        project   = container.project
                        canEdit   = container.editable?(User.current)
                    end
                    
                    # Search the DMSF folder containing the diagram
                    folderName = File.dirname(diagramName)
                    folder     = RedmineDrawio::Helpers::DrawioDmsfHelper.deep_folder_search(project, folderName)
                    
                    # Search the document in DMSF
                    file = DmsfFile.find_file_by_name project, folder, File.basename(diagramName)

                    if canEdit
                        # Diagram and document are editable
                        saveName = RedmineDrawio::Macros.dmsf_save_name project, diagramName
                    else
                        # Diagram cannot be saved, it will become not editable
                        saveName = nil
                    end
                    
                    if file
                        # Document exists, get the file path
                        filename = file.last_revision.disk_file
                        canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, file.project)
                    else
                        # Document does not exists: use a predefined diagram to start editing
                        filename = RedmineDrawio::Macros.imagePath('defaultImage'+diagramExt)
                        canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, project)
                    end
                    
                    diagram = File.read(filename, mode: 'rb')

                    if file && RedmineDrawio::Macros.pdf?(self.controller)
                        member = Member.find_by(user_id: User.current.id, project_id: file.project.id)
                        filename = file.last_revision.formatted_name(member)
                        url = static_dmsf_file_url(file, filename, :only_path => true)
                        return ActionController::Base.helpers.image_tag(url, :style => "#{inlineStyle}")
                    end

                    if RedmineDrawio::Macros.svg? diagramName
                        return RedmineDrawio::Macros.encapsulateSvg(RedmineDrawio::Macros.adaptSvg(diagram, size), inlineStyle, diagramName, title, saveName, true)
                    elsif RedmineDrawio::Macros.png? diagramName
                        # if png, encode image and remove newlines (required by Internet Explorer)
                        diagram = Base64.encode64(diagram).gsub("\n", '')
                        return RedmineDrawio::Macros.encapsulatePng(diagram, inlineStyle, diagramName, title, saveName, true)
                    else
                        tb = []
                        tb << 'pages'    unless options[:page].blank?
                        tb << 'layers'   unless layers.blank?
                        tb << 'zoom'     if zoom
                        tb << 'lightbox' if lightbox
                        
                        toolbar = if tb.empty? then nil else tb.join(' ') end
                        #style   = if size then 'style="max-width:'+size+'px;"' else "" end

                        graphOpts = {
                            'highlight'      => hilight,
                            'nav'            => false,
                            'edit'           => '_blank',
                            'lightbox'       => lightbox,
                            'resize'         => true,
                            'auto-fit'       => true,
                            'editable'       => false,
                            ##'zoom'           => zoom,
                            'page'           => page,
                            'layers'         => if layers == '*' then nil else layers end,
                            'toolbar-nohide' => (not tbautohide),
                            'toolbar'        => toolbar,
                            'xml'            => diagram
                        }
                        return RedmineDrawio::Macros.encapsulateXml(graphOpts, inlineStyle, diagramName, title, saveName, true)
                    end
                end
            end
        end

        class << self
            def drawio_url
                return '//embed.diagrams.net' if Setting.plugin_redmine_drawio['drawio_service_url'].to_s.strip.empty?
                Setting.plugin_redmine_drawio['drawio_service_url']
            end

            def dmsf_version
                Redmine::Plugin.find(:redmine_dmsf).version
            end

            def dmsf_save_name(project, diagramName)
                if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
                    Rails.logger.error "dmsf_version=#{RedmineDrawio::Macros.dmsf_version}"
                    
                    if RedmineDrawio::Macros.dmsf_version <= '1.5.8'
                        # Prior to DMSF 1.5.9 project names cannot be used for folder names
                        "#{project.id}/#{diagramName}"
                    elsif RedmineDrawio::Macros.dmsf_version <= '1.6.0'
                        # DMSF 1.5.9+ can use project name as folder
                        "#{project.name} -#{project.id}-/#{diagramName}"
                    else
                        # With DMSF 1.6.1+ the path is changed
                        "#{project.name} #{project.id}/#{diagramName}"
                    end
                else
                    "#{project.identifier}/#{diagramName}"
                end
            end

            def imagePath(defaultImage)
                File.expand_path(File.join(File.dirname(__FILE__), '../../spec', defaultImage))
            end

            def adaptSvg(svg, size)
                # Remove some scripts from the SVG (prevent some XSS issues)
                localSvg = svg.sub(/(?:<script\b[^>]*>(?:.*?)<\/script>)|(?:\\s*javascript:.*\))|(?:\\bon\w+.*?=[^>]+)|(?:src=.?(&#x?[0-9a-f]+)+)/i, '')
                # Adapt SVG to make it resizable
                localSvg = localSvg.sub(/<svg /, '<svg preserve_aspect_ratio="xMaxYMax meet" ') unless svg =~ /.* preserve_aspect_ratio=.*/
                localSvg = localSvg.sub(/<svg /, '<svg style="max-width:100%" ')
                # Add a viewBox, if missing
                localSvg = localSvg.sub(/<svg (.*) width="([0-9]+)px" height="([0-9]+)px"/, 
                                            '<svg viewBox="0 0 \2 \3" \1') unless localSvg=~ /.* viewBox="(.*)"/
                # Fix size, if forced 
                if localSvg =~ /<svg (.*) width="(?:[0-9]+)px"/
                    # width attribute presente, replace it with fized size, if present
                    localSvg = localSvg.sub(/<svg (.*) width="(?:[0-9]+)px"/, "<svg \1 width=\"#{size}\"") unless size.nil?
                elsif size.nil?
                    # no forced size and no width attribute: in no height, try to extract size from viewbox
                    localSvg = localSvg.sub(/<svg (.*) viewBox="([0-9]+) ([0-9]+) ([0-9]+) ([0-9]+)"/,
                                            '<svg \1 viewBox="\2 \3 \4 \5" width="\4px"') if localSvg =~ /.* viewBox=".*"/
                else
                    # no width attribute, but the height attribute may be present: replace it with the fixed size, if present
                    localSvg = localSvg.sub(/<svg ([^>]+?)(?: height="([0-9]+)px")?/, "<svg \1 width=\"#{size}\"")
                end
                
                localSvg
            end

            def encapsulateSvg(svg, inlineStyle, diagramName, title, saveName, isDmsf)
                dblClick = ""
                tooltip  = ""
                style    = ""
                style    = inlineStyle unless inlineStyle.blank?
                
                unless saveName.nil?
                    tagType  = if Setting.plugin_redmine_drawio['drawio_svg_enabled'] then 'svg' else 'img' end
                    dblClick = " ondblclick=\"editDiagram($(this).find('#{tagType}')[0],'#{saveName}',#{isDmsf}, '#{RedmineDrawio::Macros.js_safe(title)}', '#{diagramName}');\"" 
                    tooltip  = " title='Double click to edit diagram'"
                    style    = " style='#{inlineStyle}cursor:pointer'"
                end
                
                if Setting.plugin_redmine_drawio['drawio_svg_enabled']
                    "<span class='drawioDiagram'#{style}#{tooltip}#{dblClick}>#{svg.force_encoding("UTF-8")}</span>".html_safe
                else
                    "<span class='drawioDiagram'#{style}#{tooltip}#{dblClick}><img src='data:image/svg+xml;base64,#{Base64.strict_encode64(svg.force_encoding("UTF-8"))}'></span>".html_safe
                end
            end

            def encapsulatePng(png, inlineStyle, diagramName, title, saveName, isDmsf)
                if saveName.nil?
                    return ActionController::Base.helpers.image_tag("data:image/png;charset=utf-8;base64,#{png}", 
                                    :alt   => "Diagram #{diagramName}", 
                                    :class => "drawioDiagram",
                                    :style => "#{inlineStyle}")
                else
                    return ActionController::Base.helpers.image_tag("data:image/png;charset=utf-8;base64,#{png}", 
                                    :alt        => "Diagram #{diagramName}", 
                                    :title      => "Double click to edit diagram",
                                    :class      => "drawioDiagram",
                                    :style      => "#{inlineStyle}cursor:pointer;",
                                    :ondblclick => "editDiagram(this,'#{saveName}', #{isDmsf}, '#{RedmineDrawio::Macros.js_safe(title)}', '#{diagramName}');")
                end
            end

            def encapsulateXml(graphOpts, inlineStyle, diagramName, title, saveName, isDmsf)
                randomId = 'dg_'+('a'..'z').to_a.shuffle[0,8].join
                
                unless saveName.nil?
                    # Diagram is editable, add toolbar declarations for editing
                    graphOpts['toolbar'] = "#{graphOpts['toolbar']} edit"
                    graphOpts['toolbar-buttons'] = {
                        'edit' => {
                            'title'   => 'Edit',
                            'handler' => "(function(){editDiagram($('##{randomId}'),'#{saveName}', #{isDmsf}, '#{RedmineDrawio::Macros.js_safe(title)}', '#{diagramName}');})",
                            'image'   => 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABUAAAAVCAQAAAADHm0dAAAAbUlEQVQoz93NoRGAMBAAwXNIZCQlUEZKoQRkOqAESqAEJBIZiURGYh/DhKjPS4bTO3Pw2TwrK2MdOhKCIAQdtkD/4KTBwEGX8aVBQQq86LDErgZfbIAKHayw4bTOvRXCZIUQM9x1CBtCZMbzi25WtlGUbURavAAAAABJRU5ErkJggg==',
                        }
                    }
                end
                
                tag = "<div id=\"#{randomId}\" class=\"mxgraph\" data-mxgraph=\"#{CGI::escapeHTML(JSON.generate(graphOpts))}\"></div>".html_safe
                
                return tag if inlineStyle.empty?
                
                return "<div style=\"#{inlineStyle}\">#{tag}</div>".html_safe
            end

            def svg?(diagramName)
                diagramName =~ /\.svg$/i
            end

            def png?(diagramName)
                diagramName =~ /\.png$/i
            end

            def strip_non_filename_chars(filename)
                # Replace directory separator from \ to /
                filename = filename.gsub(/\\/, '/')
                return filename.gsub(/[\x00:*?"'<>|,;]/, '_') if Gem.win_platform?
                # *nix
                filename.gsub(/[,;|"']/, '_')
            end

            def js_safe(string)
                string.gsub(/'/){ %q(\') } if string
                ''
            end

            def svg_enabled?
                RedmineDrawio::Helpers::DrawioSettingsHelper.svg_enabled?
            end

            def pdf?(controller)
                return false if controller.is_a?(Mailer) || controller.nil?

                controller.params[:format]
            end

        end
    end
end
