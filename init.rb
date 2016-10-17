require 'redmine'
require 'json'

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

      return "<div class=\"mxgraph\" #{style} data-mxgraph=\"#{CGI::escapeHTML(graphOpts)}\"></div>".html_safe
    end
  end
  
  Redmine::WikiFormatting::Macros.register do
    desc <<EOF
TODO diagrammi editabili da attachment
EOF
    macro :drawio_attach do |obj, args|
        args, options = extract_macro_options(args, :lightbox, :fit, :resize, :zoom, :nav, :hilight)
        filename = args.first
        
        return "Please set a diagram name".html_safe unless filename
        
        filename = File.expand_path(File.dirname(__FILE__) + '/spec/defaultImage.pngxml')
        
        pngxml = File.read(filename)
        
        return "<image style=\"max-width:100%;cursor:pointer;\" onclick=\"editDiagram(this);\" src=\"data:image/png;base64,#{pngxml}\"/>".html_safe;
    end
  end

  Redmine::WikiFormatting::Macros.register do
      desc <<EOF
      Draw.io widget plugin to embed diagrams stored as DMSF documents. Example usage:
      
      {{drawio_dmsf(myDiagram)}}
      
      The diagram is drawn from document myDiagram.pngxml. If the document doesn't exists
      a default diagram is drawn. Double click the diagram to start editing.
      
      The diagram name can contain a path. For example:
      
      {{drawio_dmsf(path/to/folder/myDiagram)}}
      
      will create/edit the file myDiagram.pngxml in the DMSF folder path/to/folder of
      the current project.
EOF
      macro :drawio_dmsf do |obj, args|
          args, options = extract_macro_options(args, :lightbox, :fit, :resize, :zoom, :nav, :hilight)
          page          = obj.page
          diagramName   = args.first
          
          return "Please set a diagram name".html_safe unless diagramName

          # Add an extension, if missing
          diagramName += ".pngxml" if File.extname(diagramName.strip) == ""
          
          # Search the DMSF folder containing the diagram
          folderName = File.dirname(diagramName)
          folder     = DMSF_helper.deep_folder_search(page.wiki.project, folderName)

          # Search the document in DMSF
          file = DmsfFile.find_file_by_name page.wiki.project, folder, File.basename(diagramName)
          
          if file
            # Document exists, get the file path
            filename = file.last_revision.disk_file page.wiki.project
            canEdit  = User.current && User.current.allowed_to?(:file_manipulation, file.project)
          else
            # Document does not exists: use a predefined diagram to start editing
            filename = File.expand_path(File.dirname(__FILE__) + '/spec/defaultImage.pngxml')
            canEdit  = User.current && User.current.allowed_to?(:file_manipulation, page.wiki.project)
          end
          Rails.logger.info("====> #{filename}")          
          # Load the body of document to embed into page
          pngxml = File.read(filename)
          
          if canEdit && User.current.allowed_to?(:edit_wiki_pages, page.wiki.project)
              # Diagram and document are editable, prepare image tag attributes
              editHandler = "ondblclick=\"editDiagram(this,'#{page.wiki.project.id}/#{diagramName}');\""
              cursor      = "cursor:pointer;"
          else
              # Not editable
              editHandler = ""
              cursor      = ""
          end
          
          # Return an image tag for the diagram
          return "<image title=\"Double click to edit diagram\" style=\"max-width:100%;#{cursor}\" #{editHandler} src=\"#{pngxml}\"/>".html_safe;
      end
  end
end
