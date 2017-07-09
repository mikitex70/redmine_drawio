# Redmine draw.io plugin

[draw.io] is free online diagramming tool.

This plugin will allow embedding *draw.io diagrams* into [Redmine](http://www.redmine.org/) wiki pages, issues descriptions and issue notes.

## A note

Before submit an issue please read carefully the `README.md` file (this page): many of those that seem defects are instead the expected behavior for the macros, so read it before you start using this plugin and whenever you find unusual behaviors.

## Requirements

- Requires Redmine v2.6+. Tested with Redmine v3.1.4, v3.2.4, v3.3.3 and v3.4.0 as well as Easy Redmine 2016.05.07.

## Installation

- install `redmine_drawio` plugin:

  ```
  cd $REDMINE_HOME/plugins
  git clone https://github.com/mikitex70/redmine_drawio.git
  ```
- restart Redmine to load the new plugin
- for macro ``drawio_attach`` make sure to enable Rest API of Redmine
- for macro ``drawio_dmsf`` make sure to install the [DMSF] plugin and to enable the module for the project
- if you have troubles with the embedded editor using Internet Explorer, try a more recent version (Internet Explorer 11 should work fine) or, better, use another browser, such as Firefox or Chrome.

## Configuration

The plugin can be configured by the *Redmine* administrator via the Redmine interface, ``Administration`` -> ``Plugins`` -> ``Redmine Drawio Plugin`` -> ``Configure``.

In the configuration form you can set the Drawio server url; the default is ``//www.draw.io``, to use the default internet installation regardless of the protocol. The value can be changed to use a private drawio editor installation (see more later).

In this form you can also enable the mathematical symbol support for SVG diagrams. The default is disabled because enabling this adds about 170k of Javascript to download, so enable only if you really need it.

## Usage

There are three macros that can be used to embed diagrams in wiki pages/issues; use what best fits your needs.

### `drawio` macro
This macro draws diagrams saved in attachments. This is for compatibility with `0.1.x` versions of the plugin and is now a bit obsolete. To use it:

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

This macro render diagrams as SVG, so diagrams are interactive and navigable (link can be used to navigate to other pages).

This macro is now obsolete: you can now use SVG diagrams with the other two macros (``drawio_attach`` and ``drawio_dmsf``)
but you must import the the diagram in the *draw.io editor* and then export as SVG with an included copy of the diagram
(see the *Export as SVG* function of the *draw.io editor*).

### `drawio_attach` macro
This macro handles diagrams saved as attachments of issues or wiki pages. 

With this macro the attachments are in PNG+XML, a special format consisting in an PNG image of the diagram plus the XML diagram source embeded as a field of the image.

With an``.svg`` attachment name extension the image format is handled as SVG+XML; like the PNG+XML, this is an SVG image
with an embedded XML source of the diagram (the diagram must be created with the *draw.io editor*, normal SVG are displayed but cannot be edited).

Usage is very simple:

- make sure ``REST`` API are enabled in Redmine global settings; this is need to be able to save diagrams as attachments
- in Wiki or issue pages use the `drawio_attach` macro to specify the name of attachment containing the diagram. For example:

  ``{{drawio_attach(myDiagram)}}``

  If the diagram doesn't exists, a predefined diagram will be used as a placeholder, like this:

  ![Diagram placeholder][diagramPlaceholder]

  Double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved in a new attachment and the reference in the wiki/issue page is updated.

  The **diagram attachments are versioned** by suffixing the name with a counter. This is necessary because is not possible to update an existing attachment. Moreover, is not possible to delete attachments throught rest API (seems to be possible from Redmine 3.3.0, but I need to experiment), so the old versions of an attachment must be explicitly (manually) deleted from the Redmine web interface.

- the following macro options are available (default values are shown):
  - ``size=number`` : force image width, in pixels (default, show in original size)

In the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_attach.png) that opens a dialog that can be used to insert a macro for a new diagram to be saved as attachment (for lazy people).

The dialog can be used also for modifying a macro: simply place the caret (the cursor in the editing area) somewhere in the body of the macro, click the corresponding button in the toolbar, and the dialog will open with fields pre-filled with values from the macro source. When confirming new values, the macro source will be updated.

### `drawio_dmsf` macro
This macro handles diagrams saved in the [DMSF] repository as PNG+XML or SVG+XML images. The DMSF module must be enabled for the project to be able to use this macro.
Usage is very simple:

- enable the WebDAV functionality of the [DMSF] plugin in ``Read/Write`` mode; this is necessary to be able to save the diagram from the embedded editor. If you prefer you can disable WebDAV after all editings are done.
- in Wiki or issue pages use the `drawio_dmsf` macro to specify the path of the diagram, relative to the DMSF documents of the current project. For example:

  ``{{drawio_dmsf(diagrams/myDiagram)}}``

  The path is optional, but if specified then it must exists in the [DMSF] managed repository. If the diagram doesn't exists a predefined diagram will be used as a placeholder, like this:

  ![Diagram placeholder][diagramPlaceholder]

  Double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved (versioned) in the specified DMSF documents path for the current project, and the diagram will be automatically updated.

- the following macro options are available (default values are shown):
  - ``size=number`` : force image width, in pixels (default, show in original size)

Like for the ``drawio_attach`` macro, in the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_dmsf.png) that opens a dialog that can be used to insert a macro for a new diagram to be saved as [DMSF] document.

As for the `drawio_attach` macro, the dialog can be used for updating a macro simply by positioning the editing cursor in the right place and clicking the button.


## Some note on the drawio editor
Someone can be concerned about security in sending own diagrams to the [draw.io] site.

The diagrams aren't sent to [draw.io] for editing/rendering, but all the operations are done by the browser using only Javascript and HTML5. The only things loaded externally are the scripts and the editor page, when the diagram editor is opened. The diagram source remains local to browser/redmine site.

## Using a personal installation of draw.io

If you like, you can configure this plugin to use your own installation of the [draw.io] site. 

The build of the ``war`` file is a bit problematic because the ``drawio`` macro needs a script dinamically produced by the ``EmbedServlet2`` servlet, which is deployed in the [draw.io] site but not built from the default sources.

This servlet is excluded from build because of a missing library from Google, maybe because of copyright issues.

If you are planning to use only the ``drawio_attach`` and ``drawio_dmsf`` macros you can use the source as is without troubles, but if you want/need the ``drawio`` macro it is necessary to apply the ``embed2js.patch`` patch (included in this plugin sources).

The build steps are:

```
  git clone https://github.com/jgraph/draw.io.git
  cd draw.io
  patch -p1 < PATH_TO_DRAWIO_PLUGIN/embed2js.patch
  cd etc/build
  ant war
  cd ../../build
```

If the build ends without errors, in the ``build`` directory you should find a working version of the war file that you can deploy in your favourite servlet container (like *Tomcat*); be sure to enable the ``HTTPS`` protocol because is is required.

Then enter your *Redmine* installation, go to ``Administration`` -> ``Plugins`` -> ``Redmine Drawio plugin``, click on the ``Configure`` link and then specify your address for the ``draw.io`` site.

## Known issues

- Diagrams are rendered on the browser so they aren't visible inside a PDF export. As workaround you can print the web page as PDF document (easy with Linux, a bit more problematic in Windows), or export the diagram in PNG format and include it as image.

- There can be a browser limit on the embedded diagram size. For example Opera 11 limits _Data URIs_ size to 65000 characters. If the diagram is too big, use the ``drawio`` macro to render the diagram from an XML source.

- The ``drawio_attach`` macro doesn't completly work with issue notes: Redmine APIs allow to create new issue notes, but not to change them, so the issue note must be changed manually. As alternative use the ``drawio`` and ``drawio_dmsf`` macros, which work fine.

## TODO

- Allow specify diagrams from other other sources:

  - ~~use a file managed by the [DMSF] plugin~~
  - embed diagram as macro body
  - use GoogleDrive, Dropbox and OneDrive as possible diagram sources.
  - implement tests
  - make diagram images exportable in PDF
  - CKEditor widgets: this is a bit complicated but it would be cool. Problems:
    + first image: how to setup the initial placeholder and let be replaced when saved?
    + how to save diagrams when the wiki/issue content is new and not already saved? A "document" is needed to attach an attachment
    + url of image: the url is generated by the macro (from attachment or [DMSF]), using in a widget may require an AJAX call


## Other works
If you are using [draw.io] to create *Entity Relationship* database schemas, you may be interested to the [schema2script].

This is a Ruby command line tool that parses a [draw.io] ER diagram and produces a DDL script to initialize a database schema.

For now only [H2](http://www.h2database.com) and [Oracle](https://www.oracle.com/it/database) SQL dialects are supported, but it will grow in the future.

Related to [schema2script] is the [sboot] project, that helps to create a skeleton Java application based on [Spring boot](https://projects.spring.io/spring-boot). It creates entities, repositories ([Hibernate](http://hibernate.org) based for now), DTOs, services, REST interfaces, up to a simple CRUD web interface based on [Thymeleaf](www.thymeleaf.org) or [Angular2](https://angular.io). It also creates some tests, which can be used as a starting point for other, more specific tests.

It is in early state but it is promising; with the current version you can create a complete skeleton application starting from an ER schema, which may be a good starting point for more complex applications.


## Contributing

Any code contribution is well accepted. There are only a few rules that I would like to be respected to easy merging:

- work on ``develop`` branch and leave the ``master`` branch untouched. This is importat to keep the released versions stable.
- I would prefer comments in the style used by [gitchangelog](https://github.com/vaab/gitchangelog); this will simplify  generation of the ``CHANGELOG.md``.
  It isn't fundamental, I can edit comments and insert prefixes, or edit manually the ``CHANGELOG.md``, but it would be nice if you can help me.


[draw.io]: https://www.draw.io
[diagramPlaceholder]: spec/defaultImage.png "Placeholder for missing diagrams"
[DMSF]: https://github.com/danmunn/redmine_dmsf
