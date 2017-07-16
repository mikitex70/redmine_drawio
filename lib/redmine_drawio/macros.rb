# encoding: utf-8
require 'base64'
require 'redmine'
require 'json'

Redmine::WikiFormatting::Macros.register do
    desc <<EOF
Draw.io widget plugin to embed diagrams. Example usage:

{{drawio(diagram_attachment.xml[, ...options...])}}

Use http://draw.io to draw diagrams, save them locally and attach to wiki or issue pages.
On page view, the diagrams are sent to draw.io site for rendering.

options:
lightbox=false  : enable lightbox usage
resize=false    : enable zoom control toolbar
zoom=100        : initial zoom of diagram (percentage of original diagram)
fit=true        : fit page width (only if resize=false)
hilight=#0000ff : color to hilight hyperlinks
EOF
    
    macro :drawio do |obj, args|
        return "«Please save content first»" unless obj
        return "«Drawio diagrams are available only in issues and wiki pages»" unless obj.is_a?(WikiContent) or obj.is_a?(Issue) or obj.is_a?(Journal)
        
        args, options = extract_macro_options(args, :lightbox, :fit, :resize, :zoom, :nav, :hilight)
        filename = strip_non_filename_chars(args.first)
        
        hilight  = "#0000ff"
        lightbox = true
        fit      = true
        resize   = false
        zoom     = nil
        nav      = false
        
        hilight  = options[:hilight]          unless options[:hilight].blank?
        lightbox = options[:lightbox].to_bool unless options[:lightbox].blank?
        fit      = options[:fit].to_bool      unless options[:fit].blank?
        nav      = options[:nav].to_bool      unless options[:nav].blank?
        resize   = options[:resize].to_bool   unless options[:resize].blank?
        zoom     = options[:zoom].to_i/100.0  unless options[:zoom].blank? or not options[:zoom][/^\d+$/]
        
        if resize
            toolbar = "zoom"+(if lightbox then " lightbox" else "" end)
        else
            toolbar = nil
        end
        
        if fit
            style = 'style="max-width:100%;"'
        else
            style = ""
        end
        
        if obj.is_a?(WikiContent)
            container = obj.page
        else
            container = obj
        end
        
        attach = container.attachments.find_by_filename(filename)
        return "Diagram attachment missing or isn't a text file".html_safe unless attach && attach.is_text?
        
        file = File.open(attach.diskfile)
        contents = file.read
        file.close
        
        graphOpts = JSON.generate({
                                   "highlight" => hilight,
                                   "nav"       => nav,
                                   "edit"      => "_blank",
                                   "lightbox"  => lightbox,
                                   "resize"    => resize,
                                   "zoom"      => zoom,
                                   "toolbar"   => toolbar,
                                   "xml"       => contents
                                  })
        
        return "<div class=\"mxgraph\" #{style} data-mxgraph=\"#{CGI::escapeHTML(graphOpts)}\"></div>".html_safe+
            javascript_tag(nil, src: "#{Setting.plugin_redmine_drawio['drawio_service_url']}/embed2.js?s=general;flowchart;bpmn;lean_mapping;electrical;pid;rack;ios;aws2;azure;cisco;clipart;signs;uml;er;mockups")
    end
end

Redmine::WikiFormatting::Macros.register do
    desc <<EOF
Macro for embedding www.draw.io diagrams stored as attachments. Example usage:

{{drawio_attach(myDiagram[, ...options...])}}

The diagram is draw from the attachment myDiagram.png; if you want to use the
SVG image format, specify thw '.svg' document extension. If the attachment doesn't exists
a default diagram wil be drawn. Double click it to start editing.

Every time a diagram is saved, a new attachment will be created; for now you must 
manually delete old attachments (missing Redmine API; version 3.3.0 seems to have included
an API to delete attachments but need investigation).

options:
size=number : forced width of the diagram image, in pixels
EOF
    
    macro :drawio_attach do |obj, args|
        return "«Please save content first»" unless obj
        return "«Drawio diagrams are available only in issues and wiki pages»" unless obj.is_a?(WikiContent) or obj.is_a?(Issue) or obj.is_a?(Journal)
        
        args, options = extract_macro_options(args, :size)
        diagramName   = strip_non_filename_chars(args.first)
        
        return "«Please set a diagram name»".html_safe unless diagramName
        return "«Only png and svg diagram formats are supported»".html_safe unless diagramName =~ /.*(\.(png|svg))?$/i
        
        size = options[:size].to_i unless options[:size].blank? or not options[:size][/^\d+$/]
        
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
        
        # Search attachment position
        attach = container.attachments.find_by_filename(diagramName)
        
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
            # Diagram cannot be saved, it wil become not editable
            saveName = nil
        end
        
        if attach
            filename = attach.diskfile
        else
            filename = imagePath(if svg? diagramName then 'defaultImage.svg' else 'defaultImage.png' end)
        end
        
        diagram = File.read(filename, mode: 'rb')
        # if png, encode image and remove newlines (required by Internet Explorer)
        diagram = Base64.encode64(diagram).gsub("\n", '') unless svg? diagramName
        
        if svg? diagramName
            return encapsulateSvg(adaptSvg(diagram, size), inlineStyle, title, saveName, false)
        else
            return encapsulatePng(diagram, inlineStyle, diagramName, title, saveName, false)
        end
    end
end

if Redmine::Plugin.installed?(:redmine_dmsf)
    Redmine::WikiFormatting::Macros.register do
        desc <<EOF
Macro for embedding www.draw.io diagrams stored as DMSF documents. Example usage:

{{drawio_dmsf(myDiagram[, ...options...])}}

The diagram is drawn from the DMSF document myDiagram.png; if you want to use the
SVG image format, specify thw '.svg' document extension. If the document doesn't 
exists a default diagram will be drawn. Double click it to start editing.

The diagram name can contain a path. For example:

{{drawio_dmsf(path/to/folder/myDiagram.svg)}}

will create/edit the document myDiagram.svg in the DMSF folder path/to/folder of
the current project (the folder must exists).

options:
size=number : forced width of the diagram image, in pixels
EOF
        
        macro :drawio_dmsf do |obj, args|
            return "«Please save content first»" unless obj
            return "«Drawio diagrams are available only in issues and wiki pages»" unless obj.is_a?(WikiContent) or obj.is_a?(Issue) or obj.is_a?(Journal)
            
            args, options = extract_macro_options(args, :size)
            diagramName   = strip_non_filename_chars(args.first).force_encoding("UTF-8")
            
            return "«Please set a diagram name»".html_safe unless diagramName
            return "«Only png and svg diagram formats are supported»".html_safe unless diagramName =~ /.*(\.(png|svg))?$/i
            
            # Add an extension, if missing
            diagramName += ".png" if File.extname(diagramName.strip) == ""
            
            size = options[:size].to_i unless options[:size].blank? or not options[:size][/^\d+$/]
            
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
            folder     = DMSF_helper.deep_folder_search(project, folderName)
            
            # Search the document in DMSF
            file = DmsfFile.find_file_by_name project, folder, File.basename(diagramName)

            if canEdit
                # Diagram and document are editable
                if Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names']
                    # DMSF 1.5.9+ can use project name as folder
                    saveName = "#{project.name} -#{project.id}-/#{diagramName}"
                else
                    saveName = "#{project.id}/#{diagramName}"
                end
            else
                # Diagram cannot be saved, it wil become not editable
                saveName = nil
            end
            
            if file
                # Document exists, get the file path
                filename = file.last_revision.disk_file project
                canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, file.project)
            else
                # Document does not exists: use a predefined diagram to start editing
                filename = imagePath(if svg? diagramName then 'defaultImage.svg' else 'defaultImage.png' end)
                canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, project)
            end
            
            diagram = File.read(filename, mode: 'rb')
            # if png, encode image and remove newlines (required by Internet Explorer)
            diagram = Base64.encode64(File.read(filename, mode: 'rb')).gsub("\n", '') unless svg? diagramName
            
            if svg? diagramName
                return encapsulateSvg(adaptSvg(diagram, size), inlineStyle, title, saveName, true)
            else
                return encapsulatePng(diagram, inlineStyle, diagramName, title, saveName, true)
            end
        end
    end
end

private

def imagePath(defaultImage)
    File.expand_path(File.join(File.dirname(__FILE__), '../../spec', defaultImage))
end

def adaptSvg(svg, size)
    # Adapt SVG to make it resizable
    localSvg = svg.sub(/<svg /, '<svg preserve_aspect_ratio="xMaxYMax meet" ') unless svg =~ /.* preserve_aspect_ratio=.*/
    
    if size.nil?
        localSvg.sub(/<svg (.*) width="([0-9]+)px" height="([0-9]+)px"/, 
                     '<svg style="max-width:100%" width="\2px" height="\3px" viewBox="0 0 \2 \3" \1')
    else
        localSvg.sub(/<svg (.*) width="([0-9]+)px" height="([0-9]+)px"/,
                     "<svg style=\"max-width:100%\" width=\"#{size}\" viewBox=\"0 0 \\2 \\3\" \\1")
    end
end

def encapsulateSvg(svg, inlineStyle, title, saveName, isDmsf)
    dblClick = ""
    tooltip  = ""
    style    = ""
    style    = inlineStyle unless inlineStyle.blank?
    
    unless saveName.nil?
        dblClick = " ondblclick=\"editDiagram($(this).find('svg')[0],'#{saveName}',#{isDmsf}, '#{title}');\"" 
        tooltip  = " title='Double click to edit diagram'"
        style    = " style='#{inlineStyle}cursor:pointer'"
    end
    
    "<span class='drawioDiagram'#{style}#{tooltip}#{dblClick}>#{svg.force_encoding("UTF-8")}</span>".html_safe
end

def encapsulatePng(png, inlineStyle, diagramName, title, saveName, isDmsf)
    if saveName.nil?
        return image_tag("data:image/png;charset=utf-8;base64,#{png}", 
                         :alt   => "Diagram #{diagramName}", 
                         :class => "drawioDiagram",
                         :style => "#{inlineStyle}")
    else
        return image_tag("data:image/png;charset=utf-8;base64,#{png}", 
                         :alt        => "Diagram #{diagramName}", 
                         :title      => "Double click to edit diagram",
                         :class      => "drawioDiagram",
                         :style      => "#{inlineStyle}cursor:pointer;",
                         :ondblclick => "editDiagram(this,'#{saveName}',#{isDmsf}, '#{title}');")
    end
end

def svg?(diagramName)
    diagramName =~ /\.svg$/i
end

def strip_non_filename_chars(filename)
    # Replace directory separator from \ to /
    filename = filename.gsub(/\\/, '/')
    return filename.gsub(/[\x00:*?"<>|,;]/, '_') if Gem.win_platform?
    # *nix
    filename.gsub(/[,;|"]/, '_')
end
