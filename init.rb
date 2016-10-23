require 'redmine'
require 'json'
require 'base64'

require_dependency 'hooks/view_hooks'

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Michele Tessaro'
  description 'Wiki macro plugin for inserting drawio diagrams into Wiki pages and Issues'
  version '0.2.0'
  url 'https://github.com/mikitex70/redmine_drawio'
  author_url 'https://github.com/mikitex70'
  
  requires_redmine version: '2.6'..'3.3'
  require_dependency "drawio_dmsf_helper"
  
  # Add to_bool method to String class; this makes source more readable
  class String
    def to_bool
      return true  if self =~ (/^(true|t|yes|y|1)$/i)
      return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)

      raise ArgumentError.new "invalid value: #{self}"
    end  
  end
  
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
      args, options = extract_macro_options(args, :lightbox, :fit, :resize, :zoom, :nav, :hilight)
      filename = args.first

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
      return "Diagram attachment missing or not is a text file".html_safe unless attach && attach.is_text?

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
             javascript_tag(nil, src: "https://www.draw.io/embed2.js?s=general;flowchart;bpmn;lean_mapping;electrical;pid;rack;ios;aws2;azure;cisco;clipart;signs;uml;er;mockups")
    end
  end
  
  Redmine::WikiFormatting::Macros.register do
    desc <<EOF
Draw.io widget plugin to embed diagrams stored as attachments. Example usage:

{{drawio_attach(myDiagram)}}

The diagram is draw from the attachment myDiagram.png. If the attachment doesn't exists
a default diagram wil be drawn. Double click it to start editing.

Every time a diagram is saved, a new attachment will be created; for now you must 
manually delete old attachments (missing Redmine API; version 3.3.0 seems to have included
an API to delete attachments).
EOF

    macro :drawio_attach do |obj, args|
        # in app/models/project.rb
        #return "" unless @Project.module_enabled?("MODULE NAME")
        args, options = extract_macro_options(args)
        diagramName = args.first
        
        return "Please set a diagram name".html_safe unless diagramName
        
        if obj.is_a?(WikiContent)
            container = obj.page
            canEdit   = User.current.allowed_to?(:edit_wiki_pages, @project)
        else
            container = obj
            canEdit   = container.editable?(User.current)
        end
        
        # Add an extension, if missing
        diagramName += ".png" if File.extname(diagramName.strip) == ""
        
        if diagramName =~ /_\d+\./
            saveName = diagramName.sub(/_(\d+)/) {|v| v.next } # increment version
        else
            saveName = diagramName.sub(/(\.\w+)$/, '_1\1') # set versione to _1
        end
        
        # Search attachment position
        attach = container.attachments.find_by_filename(diagramName)
        
        if attach
            if attach.is_text?
                return "Diagram as XML not supported: start a new diagram and import the old"
            else
                filename = attach.diskfile
            end
        else
            filename = File.expand_path(File.dirname(__FILE__) + '/spec/defaultImage.png')
        end
        
        pngxml = File.read(filename)
        pngxml = Base64.encode64(pngxml)
        
        if canEdit
        #if canEdit && User.current.allowed_to?(:edit_wiki_pages, page.wiki.project)
            # Diagram and document are editable
            return image_tag("data:image/png;base64,#{pngxml}", 
                                :alt   => "Diagram #{diagramName}", 
                                :title => "Double click to edit diagram",
                                :class => "drawioDiagram",
                                :style => "max-width:100%;cursor:pointer;",
                                :ondblclick => "editDiagram(this,'#{saveName}',false);")
        else
            # Not editable
            return image_tag("data:image/png;base64,#{pngxml}", 
                                :alt   => "Diagram #{diagramName}", 
                                :class => "drawioDiagram",
                                :style => "max-width:100%")
        end
    end
  end

  Redmine::WikiFormatting::Macros.register do
      desc <<EOF
Draw.io widget plugin to embed diagrams stored as DMSF documents. Example usage:

{{drawio_dmsf(myDiagram)}}

The diagram is drawn from the DMSF document myDiagram.png. If the document doesn't 
exists a default diagram will be drawn. Double click it to start editing.

The diagram name can contain a path. For example:

{{drawio_dmsf(path/to/folder/myDiagram)}}

will create/edit the document myDiagram.png in the DMSF folder path/to/folder of
the current project.
EOF

      macro :drawio_dmsf do |obj, args|
          #return "" unless @Project.module_enabled?("redmine_dmsf")
          
          #Rails.logger("redmine_dmsf? #{@Project.module_enabled?("redmine_dmsf")}")
          #Rails.logger("dmsf? #{@Project.module_enabled?("dmsf")}")
          
          args, options = extract_macro_options(args)
          diagramName   = args.first
          
          return "Please set a diagram name".html_safe unless diagramName

          if obj.is_a?(WikiContent)
              container = obj.page
              canEdit   = User.current.allowed_to?(:edit_wiki_pages, @project)
          else
              container = obj
              canEdit   = container.editable?(User.current)
          end

          # Add an extension, if missing
          diagramName += ".png" if File.extname(diagramName.strip) == ""
          
          # Search the DMSF folder containing the diagram
          folderName = File.dirname(diagramName)
          folder     = DMSF_helper.deep_folder_search(container.wiki.project, folderName)

          # Search the document in DMSF
          file = DmsfFile.find_file_by_name container.wiki.project, folder, File.basename(diagramName)
          
          if file
              # Document exists, get the file path
              filename = file.last_revision.disk_file container.wiki.project
              canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, file.project)
          else
              # Document does not exists: use a predefined diagram to start editing
              filename = File.expand_path(File.dirname(__FILE__) + '/spec/defaultImage.png')
              canEdit  = canEdit && User.current && User.current.allowed_to?(:file_manipulation, container.wiki.project)
          end
          
          # Load the body of document to embed into page
          pngxml = File.read(filename)
          pngxml = Base64.encode64(pngxml)
          
          if canEdit 
          #if canEdit && User.current.allowed_to?(:edit_wiki_pages, page.wiki.project)
              # Diagram and document are editable
              return image_tag("data:image/png;base64,#{pngxml}", 
                                    :alt   => "Diagram #{diagramName}", 
                                    :title => "Double click to edit diagram",
                                    :class => "drawioDiagram",
                                    :style => "max-width:100%;cursor:pointer;",
                                    :ondblclick => "editDiagram(this,'#{container.wiki.project.id}/#{diagramName}',true);")
          else
              # Not editable
              image_tag("data:image/png;base64,#{pngxml}", 
                            :alt   => "Diagram #{diagramName}", 
                            :class => "drawioDiagram",
                            :style => "max-width:100%;")
          end
      end
  end
end
