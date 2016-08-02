require 'redmine'
require 'json'

require_dependency 'hooks/view_hooks'

Redmine::Plugin.register :redmine_drawio do
  name 'Redmine Drawio plugin'
  author 'Michele Tessaro'
  description 'Wiki macro plugin for inserting drawio diagrams into Wiki pages and Issues'
  version '0.1.1'
  url 'https://github.com/mikitex70/redmine_drawio'
  author_url 'https://github.com/mikitex70'
  
  requires_redmine version: '2.6'..'3.2'
  
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
end
