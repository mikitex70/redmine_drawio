# Redmine draw.io plugin

[draw.io] is free online diagramming tool.

This plugin will allow embedding *draw.io diagrams* into [Redmine](http://www.redmine.org/) wiki pages, issues descriptions and issue notes.

## A note

Before submit an issue please read carefully the `README.md` file (this page): many of those that seem defects are instead the expected behavior for the macros, so read it before you start using this plugin and whenever you find unusual behaviors.

## Requirements

- Requires Redmine v2.6+. Tested with Redmine v3.1.4, v3.2.4, v3.3.3, v3.4.0, v4.0.4, v5.0.1 as well as Easy Redmine 2016.05.07.

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

In the configuration form you can set the Drawio server url; the default is `//embed.diagrams.net`, to use the default internet installation regardless of the protocol. The value can be changed to use a private drawio editor installation (see more later).

An important configuration is `Enable SVG diagrams`: diagrams in SVG format can introduce [Cross-Site Scripting](https://en.wikipedia.org/wiki/Cross-site_scripting) security issues, so from version `1.2.0` they are handled in a different way:
* if the field is checked, the behaviour is similar to previous releases: SVG diagrams are rendered as-is, in particular hyperlinks can be used to navigate to other pages (or sites). XSS issues are mitigated, but cannot be completely removed
* if the field is unchecked (default), SVG diagrams are encoded and rendered as images. The quality is the same as original SVG (they scale in the same way) and there are no security issues, but hyperlink don't work.

So the *Redmine administrator* is responsible to choose a security level adequate to the installation (Internet vs Intranet, for example), and the usage (how much important are hyperlinks?).

In this form you can also enable the mathematical symbol support for SVG diagrams. The default is disabled because enabling this adds about 170k of Javascript to download, so enable only if you really need it.


## Security

By configuring the header [Content-Security-Policy](https://content-security-policy.com/) in the Redmine webserver is possible to restrict what can be loaded in a web page. An example value is this:
```
default-src 'self'; script-src 'unsafe-inline' 'self' 'unsafe-eval'; connect-src 'self'; img-src 'self'; style-src 'unsafe-inline' 'self'
```

This setting is very restrictive: is allows loading scripts, stylesheets and images only from local server. This kind of setting is too restrictive for the `redmine_drawio` plugin, but can be relaxed a bit:
```
default-src 'self' embed.diagrams.net; script-src 'unsafe-inline' 'self' 'unsafe-eval' ; connect-src 'self'; img-src 'self' data: embed.diagrams.net; style-src 'unsafe-inline' 'self'
```

In this case we have relaxed the policy allowing to load scripts and images from `embed.diagrams.net` (the external site which serves the diagram editor). If security is an issue, you can use a local installation of the editor website (see the section *Using a personal installation of draw.io*), modifying the `Content-Security-Policy` header accordingly.

Another value added in the configuration above is the `data:` for the `image-src` policy: this allows to use inline embedded images, and is fundamental for the plugin to work as it is the way edited images are shown after editing without the need to reload the page.

An additional important configuration that may be present is the `frame-src`: it configures the policy for the use of iframes. The diagram editor is run in a `iframe`, so the setting must be relaxed to allow loading contents from `embed.diagrams.net`. Example (to be added in the `Content-Security-Policy` header):
```
frame-src: embed.diagrams.net 'self'; child-src: embed.diagrams.net 'self'
```


## Usage

There are three macros that can be used to embed diagrams in wiki pages/issues; use what best fits your needs.


### `drawio` macro

This macro is now deprecated and not working anymore. Use the `drawio_attach` macro as a direct replacement.


### `drawio_attach` macro

This macro handles diagrams saved as attachments of issues or wiki pages.

The supported diagrams format are:
* `xml`: normal diagram source in XML format
* `png`: PNG image with an embedded XML source of the diagram (PNG+XML)
* `svg`: SVG image with an embedded XML source of the diagram (SVG+XML)

The `xml` format uses a Javascript viewer to render the diagram runtime. It maybe a bit slow, but adds navigation options to the diagram (zoom, page and layer selector).

With this macro the attachments are in PNG+XML, a special format consisting in an PNG image of the diagram plus the XML diagram source embeded as a field of the image.

With an``.svg`` attachment name extension the image format is handled as SVG+XML; like the PNG+XML, this is an SVG image
with an embedded XML source of the diagram (the diagram must be created with the *draw.io editor*, normal SVG are displayed but cannot be edited).

**WARNING**: SVG images can introduce [XSS(Cross-Site Scripting)](https://en.wikipedia.org/wiki/Cross-site_scripting) security issues. For internet deploys make sure the `Enable SVG diagrams` configuration options is unchecked, so the svg diagrams will rendered as a base64 encoded image (no XSS issues, same quality, but hyperlinks will not work).

From version `1.0.0` are also supported diagrams in XML format (as used with the old `drawio` macro).

Usage is very simple:

- **make sure ``REST`` API are enabled in Redmine global settings**; this **is needed** to be able to save diagrams as attachments. To enable it, go into `Administration` -> `Settings` -> `API` tab and check the `Enable REST web service` flag.
- in Wiki or issue pages use the `drawio_attach` macro to specify the name of attachment containing the diagram. For example:

  ``{{drawio_attach(myDiagram)}}``

  If the diagram doesn't exists, a predefined diagram will be used as a placeholder, like this:

  ![Diagram placeholder][diagramPlaceholder]

  For PNG and SVG diagrams, double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved in a new attachment and the reference in the wiki/issue page is updated.
  
  For XML diagrams, a toolbar will appear when the mouse enters the diagram area; in the toolbar there is a button for start editing the diagram.

  The **diagram attachments are versioned** by suffixing the name with a counter. This is necessary because is not possible to update an existing attachment. Moreover, is not possible to delete attachments throught rest API (seems to be possible from Redmine 3.3.0, but I need to experiment), so the old versions of an attachment must be explicitly (manually) deleted from the Redmine web interface.

- the following macro options are available (default values are shown):
  - ``size=number`` : force image width, in pixels (default, show in original size)
  - only for XML diagrams:
    - ``hilight=#0000ff``: color to highlight diagram hyperlinks
    - ``tbautohide=true``: if `false` the toolbar is always visibile (if there are buttons), else it will be shown only when the mouse enters the diagram area
    - ``lightbox=false``: activates the *LightBox* viewer button in the toolbar
    - ``zoom=false``: activates the zoom buttons in the toolbar
    - ``page=number``: if not empty a *page selector* will appear in the toolbar (for multi-page diagrams) and the initial page (starting from 0) will be selected
    - ``layers``: if set as a list of space separated number of layers, those layer will be activated for default, and a *layer selector* control will appear in the toolbar.

In the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_attach.png) that opens a dialog that can be used to insert a macro for a new diagram to be saved as attachment (for lazy people).

The dialog can be used also for modifying a macro: simply place the caret (the cursor in the editing area) somewhere in the body of the macro, click the corresponding button in the toolbar, and the dialog will open with fields pre-filled with values from the macro source. When confirming new values, the macro source will be updated.


### `drawio_dmsf` macro
This macro handles diagrams saved in the [DMSF] repository as PNG+XML or SVG+XML images, or as XML documents (from version `1.0.0`). The DMSF module must be enabled for the project to be able to use this macro.

Usage is very simple:

- **enable the WebDAV functionality of the [DMSF] plugin in ``Read/Write`` mode**; this is necessary to be able to save the diagram from the embedded editor. If you prefer you can disable WebDAV after all editings are done.
  **NOTE**: starting from the [DMSF] plugin version `v3.0.0` you need to modify the Redmine `config/additional_environment.rb` file; see [here](https://github.com/danmunn/redmine_dmsf#webdav) for more details.
- in Wiki or issue pages use the `drawio_dmsf` macro to specify the path of the diagram, relative to the DMSF documents of the current project. For example:

  ``{{drawio_dmsf(diagrams/myDiagram)}}``

  The path is optional, but if specified then it must exists in the [DMSF] managed repository. If the diagram doesn't exists a predefined diagram will be used as a placeholder, like this:

  ![Diagram placeholder][diagramPlaceholder]

  For PNG and SVG diagrams, double click on the diagram to start editing with the embedded editor. When you save the the diagram the editor will close, the diagram will be saved in a new attachment and the reference in the wiki/issue page is updated.
  
  For XML diagrams, a toolbar will appear when the mouse enters the diagram area; in the toolbar there is a button for start editing the diagram.

- the following macro options are available (default values are shown):
  - ``size=number`` : force image width, in pixels (default, show in original size)
  - only for XML diagrams:
    - ``hilight=#0000ff``: color to highlight diagram hyperlinks
    - ``tbautohide=true``: if `false` the toolbar is always visibile (if there are buttons), else it will be shown only when the mouse enters the diagram area
    - ``lightbox=false``: activates the *LightBox* viewer button in the toolbar
    - ``zoom=false``: activates the zoom buttons in the toolbar
    - ``page=number``: if not empty a *page selector* will appear in the toolbar (for multi-page diagrams) and the initial page (starting from 0) will be selected
    - ``layers``: if set as a list of space separated number of layers, those layer will be activated for default, and a *layer selector* controlo will appear in the toolbar.

Like for the ``drawio_attach`` macro, in the toolbar editor there is a button with icon ![drawio_attach icon](assets/images/jstb_drawio_dmsf.png) that opens a dialog that can be used to insert a macro for a new diagram to be saved as [DMSF] document.

As for the `drawio_attach` macro, the dialog can be used for updating a macro simply by positioning the editing cursor in the right place and clicking the button.


## Diagrams in PDF export

Starting from version `1.4.2`, diagrams are included in PDF exports.

There is a limitation: if the diagram is saved in a document managed by the [DMSF] plugin you need at least the **'v3.0.3'** version of the plugin to make the export work. And this means that it only works starting with **Redmine 5**.


## Some note on the drawio editor

Someone can be concerned about security in sending own diagrams to the [draw.io] site.

The diagrams aren't sent to [draw.io] for editing/rendering, but all the operations are done by the browser using only Javascript and HTML5. The only things loaded externally are the scripts and the editor page, when the diagram editor is opened. The diagram source remains local to browser/redmine site.


## Using a personal installation of draw.io

If you like, you can configure this plugin to use your own installation of the [draw.io] site. 

The build of the ``war`` file is a bit problematic because the ``drawio`` macro needs a script dynamically produced by the ``EmbedServlet2`` servlet, which is deployed in the [draw.io] site but not built from the default sources.

This servlet is excluded from build because of a missing library from Google, maybe because of copyright issues.

If you are planning to use only the ``png`` and ``svg`` formats you can use the source as is without troubles, but if you want/need diagrams in the ``xml`` format it is necessary to apply the ``embed2js.patch`` patch (included in this plugin sources).

The build steps are:

```bash
git clone https://github.com/jgraph/draw.io.git
cd draw.io
patch -p1 < PATH_TO_DRAWIO_PLUGIN/embed2js.patch
cd etc/build
ant war
cd ../../build
```

If the build ends without errors, in the ``build`` directory you should find a working version of the war file that you can deploy in your favourite servlet container (like *Tomcat*); be sure to enable the ``HTTPS`` protocol because is is required.

Then enter your *Redmine* installation, go to ``Administration`` -> ``Plugins`` -> ``Redmine Drawio plugin``, click on the ``Configure`` link and then specify your address for the ``draw.io`` site.


## Local MathJax installation

The [MathJax] library is used to render mathematical symbols in SVG diagrams.

Once enabled from the ``Redmine Drawio plugin`` settings it is loaded from internet every time a wiki page is rendered.

This can be slow (it's a big library) and maybe not doable behind a proxy or without an internet connection.

However it is possible to use a local installation of the library following these steps:

1. install the [MathJax] library locally (through zip, svn, git, npm, ecc.) in a web server; for detailed instructions see [here](http://docs.mathjax.org/en/latest/installation.html)
2. go to ``Administration`` -> ``Plugins`` -> ``Redmine Drawio plugin``, click on the ``Configure`` link and:
   1. select the ``SVG mathemathics support``
   2. fill the ``MathJax library URL`` with the URL of the installation, for example ``//my.server/mathjax/MathJax.js``

Once updated the settings, go to a wiki page with a mathematical SVG diagram and you should see the diagram exactly as before. You can check from where the library is downloaded using the browser developer tools.


## Known issues

- Diagrams in ``xml`` format are rendered on the browser so they aren't visible inside a PDF export. As workaround you can print the web page as PDF document (easy with Linux, a bit more problematic in Windows), or export the diagram in PNG format and include it as image.

- There can be a browser limit on the embedded diagram size. For example Opera 11 limits _Data URIs_ size to 65000 characters. If the diagram is too big, use the ``xml`` diagram format to render the diagram from an XML source.

- The ``drawio_attach`` macro doesn't completly work with issue notes: Redmine APIs allow to create new issue notes, but not to change them, so the issue note must be changed manually. As alternative use ``drawio_dmsf`` macro, which works fine.


## TODO

- Allow specify diagrams from other other sources:

  - ~~use a file managed by the [DMSF] plugin~~
  - embed diagram as macro body
  - ~~use GoogleDrive, Dropbox and OneDrive as possible diagram sources.~~ I don't have time, and I think is not so useful
  - implement tests
  - ~~make diagram images exportable in PDF~~
  - CKEditor widgets: this is a bit complicated but it would be cool. Problems:
    + first image: how to setup the initial placeholder and let be replaced when saved?
    + how to save diagrams when the wiki/issue content is new and not already saved? A "document" is needed to attach an attachment
    + url of image: the url is generated by the macro (from attachment or [DMSF]), using in a widget may require an AJAX call


## Contributing

Any code contribution is well accepted. There are only a few rules that I would like to be respected to easy merging:

- work on ``develop`` branch and leave the ``master`` branch untouched. This is importat to keep the released versions stable.
- I would prefer comments in the style used by [gitchangelog](https://github.com/vaab/gitchangelog); this will simplify generation of the ``CHANGELOG.md``.
  It isn't fundamental, I can edit comments and insert prefixes, or edit manually the ``CHANGELOG.md``, but it would be nice if you can help me.


[draw.io]: https://www.draw.io
[diagramPlaceholder]: spec/defaultImage.png "Placeholder for missing diagrams"
[DMSF]: https://github.com/danmunn/redmine_dmsf
[MathJax]: https://www.mathjax.org/
