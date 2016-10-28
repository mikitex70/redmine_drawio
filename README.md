# Redmine draw.io plugin

[draw.io] is free online diagramming tool.

This plugin will allow embedding *draw.io diagrams* into [Redmine](http://www.redmine.org/) wiki pages and issues.

## Requirements

- Requires Redmine v2.6+. Tested with Redmine v3.1.4, v3.2.3 and v3.3.0.

## Installation

- install `redmine_drawio` plugin:

  ```
  cd $REDMINE_HOME/plugins
  git clone https://github.com/mikitex70/redmine_drawio.git
  ```

- restart Redmine to load the new plugin

## Usage

There are three macros that can be used to embed diagrams in wiki pages/issues; use what best fits your needs.

### `drawio` macro
This macro draws diagrams saved in attachments. This is for compatibility with `0.1.x` versions of the plugin. To use it:

- save your [draw.io] diagram locally and upload it as attachment to a Wiki or issue page.

- in Wiki (or issue) pages use the `drawio` macro to load the widget, specifying the name of the attachment. For example:

  ```
  {{drawio(activity.xml, options)}}
  ```

- the following macro options are available (default values are shown):

  - ``lightbox=false`` : enable lightbox usage
  - ``resize=false`` : enable zoom control box
  - ``zoom=100`` : initial zoom of diagram (percentage of original diagram)
  - ``fit=true`` : fit page width (only if ``resize=false``)
  - ``hilight=#0000ff`` : color to hilight hyperlinks
  
With this macro diagrams are drawn using SVG (or maybe Canvas) so they are interactive: they are navigable,
they respond to ``over`` and ``click`` actions. Hyperlinks can be used to navigate to other items.

### `drawio_attach` macro
This macro handles diagrams saved as attachments of issues or wiki pages. 

With this macro the attachments are in PNG+XML format, a special format consisting in an PNG image of the diagram plus the XML diagram source embeded as a field of the image.

Usage is very simple:

- in Wiki or issue pages use the `drawio_attach` macro to specify the name of attachment containing the diagram. For example:

  ``{{drawio_attach(myDiagram)}}``

  If the diagram doesn't exists, a predefined diagram will be used as a placeholder:

  ![Diagram placeholder][diagramPlaceholder]

  Double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved in a new attachment and the reference in the wiki/issue page is updated.

  The diagram attachments are versioned by suffixing the name with a counter. This is necessary because is not possible to update an existing attachment. Moreover, is not possible to delete attachments throught rest API (seems to be possible from Redmine 3.3.0, but I need to experiment), so the old versions of an attachment must be explicitly deleted from the Redmine web interface.

In the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_attach.png) that can be used to insert a macro for a new diagram to be saved as attachment (for lazy people).

### `drawio_dmsf` macro
This macro handles diagrams saved in the [DMSF] repository as PNG+XML images. The DMSF module must be enabled for the project to be able to use this macro.
Usage is very simple:

- enable the WebDAV functionality of the [DMSF] plugin; this is necessary to be able to save the diagram from the embedded editor. If you prefer you can disable WebDAV after all editings are done.
- in Wiki or issue pages use the `drawio_dmsf` macro to specify the path of the diagram, relative to the DMSF documents of the current project. For example:

  ``{{drawio_dmsf(diagrams/myDiagram)}}``

  The path is optional. If the diagram doesn't exists, a predefined diagram will be used as a placeholder:

  ![Diagram placeholder][diagramPlaceholder]

  Double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved (versioned) in the specified DMSF documents path for the current project, and the diagram will be automatically updated.

Like for the ``drawio_attach`` macro, in the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_dmsf.png) that can be used to insert a macro for a new diagram to be saved as [DMSF] document.

## Some note on the drawio editor
Someone can be concerned about security in sending own diagrams to the [draw.io] site.

The diagrams aren't sent to [draw.io] for editing/rendering, but all the operations are done by the browser using only Javascript and HTML5. The only thing loaded externally are the scripts and the editor page, when the diagram editor is opened. The diagram source remains local to browser/redmine sizte.

## Known issues

- Diagrams are rendered on the browser so they aren't visible inside a PDF export. As workaround you can print the web page as PDF document (easy with Linux, a bit more problematic in Windows), or export the diagram in PNG format and include it as image.

- There can be a browser limit on the embedded diagram size. For example Opera 11 limits _Data URIs_ size to 65000 characters.

- The embedded diagrams probably aren't working on Internet Explorer (_Data URIs_ not allowewd in HTML).

## TODO

- Allow specify diagrams from other other sources:

  - ~~use a file managed by the [DMSF] plugin~~
  - embed diagram as macro body
  - use GoogleDrive, Dropbox and OneDrive as possible diagram sources.
  - implement tests
  - make diagram images exportable in PDF

[draw.io]: https://www.draw.io
[diagramPlaceholder]: spec/defaultImage.png "Placeholder for missing diagrams"
[DMSF]: https://github.com/danmunn/redmine_dmsf
