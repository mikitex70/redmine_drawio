# Redmine draw.io plugin

[draw.io](https://www.draw.io) is free online diagramming tool.

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
This macro draws diagrams save in attachments. This is for compatibility with `0.1.x` versions of the plugin. To use it:

- save your [draw.io](https://www.draw.io) diagram locally and upload it as attachment to wiki or issue page.

- in Wiki pages use the `drawio` macro to load the widget, specifying the name of the attachment. For example:

  ```
  {{drawio(activity.xml)}}
  ```

- the following macro options are available (default values are shown):

  - ``lightbox=false`` : enable lightbox usage
  - ``resize=false`` : enable zoom control box
  - ``zoom=100`` : initial zoom of diagram (percentage of original diagram)
  - ``fit=true`` : fit page width (only if ``resize=false``)
  - ``hilight=#0000ff`` : color to hilight hyperlinks

### `drawio_dmsf` macro
This macro handle diagrams saved in the [DMSF](https://github.com/danmunn/redmine_dmsf) repository. Usage is very simple:

- in Wiki or issue pages use the `drawio_dmsf` macro to specify the path of the diagram. For example:

  ``{{drawio_dmsf(diagrams/myDiagram)}}``

  The path is optional. If the diagram doesn't exists, a predefined diagram will be used as a placeholder:

  ![Diagram placeholder](diagramPlaceholder.png)

  Double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved in the specified DMSF documents path for the current project, and the diagram will be automatically updated.

## Some note on the drawio editor
Someone can be concerned about security in sending own diagrams to the [drawio](https://www.draw.io) site

## Known issues

- Diagrams are rendered on the browser so they aren't visible inside a PDF export. As workaround you can print the web page as PDF document (easy with Linux, a bit more problematic in Windows), or export the diagram in PNG format and include it as image.

## TODO

- Allow specify diagrams from other other sources:

  - use a file managed by the [DMSF](https://github.com/danmunn/redmine_dmsf) plugin
  - embed diagram as macro body
  - use GoogleDrive, Dropbox and OneDrive as possible diagram sources.
  - implement tests
