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

## Known issues

- Diagrams are rendered on the browser so they aren't visible inside a PDF export. As workaround you can print the web page as PDF document (easy with Linux, a bit more problematic in Windows), or export the diagram in PNG format and include it as image.

## TODO

- Allow specify diagrams from other other sources:

  - use a file managed by the [DMSF](https://github.com/danmunn/redmine_dmsf) plugin
  - embed diagram as macro body
  - use GoogleDrive, Dropbox and OneDrive as possible diagram sources.
  - implement tests
