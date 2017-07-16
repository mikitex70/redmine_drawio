# Changelog

## v0.8.0 (2017-07-16)

### New

* Tested on Redmine 3.4.0-stable. [Michele Tessaro]

* Added russian translation. [Denis Sidorov]

  Russian for drawio_jstoolbar

* Added mathemathics support in SVG (refs #17) [Michele Tessaro]

  Added support for mathematical symbols in SVG diagrams.
  The support must be enabled in the plugin configuration as it adds about
  170k of Javascript.

* Added Simplified Chinese translation file. [Steven.W@UTH]

### Changes

* Translated messages for Simplifed Chinese. [Steven.W@UTH]

  Translation of file drawio_jstoolbar-zh.js into Simplified Chinese.

### Fix

* Fixed duplicated notes with EasyRedmine (fixes #40) [Michele Tessaro]

* Fixed foreign characters in SVG diagrams (refs #36) [Michele Tessaro]

* Fixed invalid character stripping from filenames (refs #35) [Michele Tessaro]

  The filenames must be stripped from some characters that can cause
  troubles in the filesystem or in the web page.
  The old algorithm was too strict and was removing international
  characters too.

* Fixed typo in drawio_jstoolbar-en.js. [Denis Sidorov]

* Fixed saving on DMSF 1.5.9+ (fixes #32) [Michele Tessaro]

  Fixed saving on DMSF 1.5.9+ when &quot;Use project name for project folder&quot;
  is selected in the plugin settings.
  Note that the version tagged 1.5.9 has a bug in the webdav path URI: at
  this time the master branch must be used.


## v0.7.1 (2017-06-12)

### Changes

* Updated changelog. [Michele Tessaro]

* Disabled SSL if drawio service has HTTP protocol. [Michele Tessaro]

  Disabling SSL can help use on using local drawio installations.
  Now you can use a local installation without the need to create a
  certificate.
  Do not use HTTP protocol if your drawio is exposed to Internet.

* Added a note to the documentation. [Michele Tessaro]

### Fix

* Fixed a check on diagram filename extension. [Michele Tessaro]


## v0.7.0 (2017-06-11)

### New

* Skipped authentication on attachment update (fixes #23) [Michele Tessaro]

  The drawio_attach macro can upload a new version of diagram without
  asking for authentication.
  This can authentication problems with plugin provided providers.
  The drawio_dmsf works as previous: no way to bypass secondary login.

* Decoded HTTP error 422 (closes #22) [Michele Tessaro]

  When saving diagrams as attachments, if the attachment is too big
  Redmine return an HTTP 422 error (Enprocessable Entity).
  Now a more clear message would be reporte.

* Added support for internationalization. [Michele Tessaro]

* Editing support for textile button macros. [Michele Tessaro]

  Placing che cursor in a body macro e clicking the macro button will open
  the dialog pre-filled with the values extracted from the macro heading.
  This can be useful to change values with a pre-validating dialog instead
  of changing he macro directly, with the risk of syntax errors or wrong
  parameter names.

* CKEditor support (refs #21) [Michele Tessaro]

  If the Redmine CKEditor plugin is in use, one button (or two, if the
  DMSF plugin is installed) will be added to the toolbar.
  Handling of diagrams inside of the editor is not easy because the
  document body must be saved before the diagrams, so at this time the
  dialogs are only shortcuts for inserting macros.
  Maybe I can add embedded editing for already created diagrams.

* Disabled dmsf editor button if no redmine_dmsf plugin. [Michele Tessaro]

  The editor button for inserting the drawio_dmsf macro now will be draw
  only if the redmine_dmsf plugin is active.

* Added EasyRedmine detection. [Michele Tessaro]

* Refactor to let work with easyredmine. [Michele Tessaro]

* Disabled dmsf editor button if no redmine_dmsf plugin. [Michele Tessaro]

  The editor button for inserting the drawio_dmsf macro now will be draw
  only if the redmine_dmsf plugin is active.

* Added EasyRedmine detection. [Michele Tessaro]

* Refactor to let work with easyredmine (fixes #13, #18, #19) [Michele Tessaro]

* Ignored case when checking if SVG diagram requested. [Michele Tessaro]

  Now the drawio_attach and drawio_dmsf macros will check the document
  extension in a case-insensitive manner; extensions like svg, SVG, Svg
  are all interpreted as a request to use an SVG diagram format.

* Added embedded editor support for SVG images (closes #17) [Michele Tessaro]

### Changes

* Udated changelog. [Michele Tessaro]

* Skipped issue note creation in EasyRedmine (refs #28) [Michele Tessaro]

  EasyRedmine can update attachments so there is no need to add a new
  issue note (a journal) when a diagram is updated.

* Updated documentation. [Michele Tessaro]

### Fix

* Fixed updating diagrams on private notes (fixes #28) [Michele Tessaro]

* Fixed saving of SVGs (fixes #26, #26) [Michele Tessaro]

* Fixed SVG corrupted after save before reload (fixes #25) [Michele Tessaro]

  After editing an SVG diagram and saving it, double clicking on the
  diagram without reloading page causes an `Not a diagram` error in the
  drawio diagram editor.
  Seems that updating the SVG in the page causes the insertion of an
  `&quot;=&quot;&quot;&#x27; text, that confuses the parser.
  Removed with an regex, but not identified the source problem (maybe
  related to the `XMLSerializer` Firefox browser object).

* Fixed macros after refactor for easyredmine (refs #18) [Michele Tessaro]

* Fixed macros after refactor for easyredmine (refs #18) [Michele Tessaro]

### Other

* Fix #27: Javascript error match on undefined. [Alexander Menk]

  Prevented saving in EasyRedmine issue note

* Fix #27: Javascript error match on undefined. [Alexander Menk]

  Prevented saving in EasyRedmine issue note


## v0.6.0 (2017-04-11)

### New

* Added embedded editor support for SVG images (closes #17) [Michele Tessaro]


## v0.5.0 (2017-01-26)

### New

* Added configuration of draw.io server (implements #12) [Michele Tessaro]

  Added a configuration dialog which can be used to change the default URL
  of the draw.io server.
  Added also notes on how to build a fully functionally war file of the
  draw.io site (the default is missing of a servlet).

* Added support for issue notes. [Michele Tessaro]

### Fix

* Fixed UTF-8 encoding in init.rb (fixes #14) [Michele Tessaro]

* Fixed computation of Redmine URL (fixes #11) [Michele Tessaro]

  Fixed a missing slash in the url while uploading attachments throught
  drawio_attach macro, that caused &quot;Not found&quot; errors.


## v0.4.0 (2016-12-10)

### New

* Added option to set diagram size (refs #8) [Michele Tessaro]

  Added option ``size`` to macros ``drawio_attach`` and ``drawio_dmsf`` to
  allow resize diagram image.
  The size option sets the image width, in pixels; default is original
  image width.

### Changes

* Added notes on code contributions. [Michele Tessaro]

### Fix

* Load &#x27;loading&#x27; image using protocol-relative paths. [Javango]

  When loading the ajax-loader image from a https site I am getting the following error message,  this switches to protocol-relative paths.

  Mixed Content: The page at &#x27;https://support.my-site.com/issues/9999&#x27; was loaded over HTTPS, but requested an insecure image &#x27;http://www.draw.io/images/ajax-loader.gif&#x27;. This content should also be served over HTTPS.

* Fixed errors when used outside wiki pages (refs #9) [Michele Tessaro]

* Fixed redmine path with custom route (fixes #7) [Michele Tessaro]

  Fixed calculation of Redmine web path when using custom routes, such
  when using a single project as Redmine home page (see
  http://www.redmine.org/boards/2/topics/32811)

* Load &#x27;loading&#x27; image using protocol-relative paths. [Javango]

  When loading the ajax-loader image from a https site I am getting the following error message,  this switches to protocol-relative paths.

  Mixed Content: The page at &#x27;https://support.my-site.com/issues/9999&#x27; was loaded over HTTPS, but requested an insecure image &#x27;http://www.draw.io/images/ajax-loader.gif&#x27;. This content should also be served over HTTPS.


## v0.3.2 (2016-11-22)

### Changes

* Updated documentation. [Michele Tessaro]

* Human decoded DMSF HTTP error codes. [Michele Tessaro]

  Added decoding of HTTP error codes returned by the WebDAV interface of
  the DMSF plugin; now the message is more explanatory of the cause.

### Fix

* Various fixes (refs #5) [Michele Tessaro]

  * fixed opening images from Redmine running on Windows (such as with
  Bitnami)
  * fixed editing with Internet Explorer (tested with 11, needed 9+)
  * fixed editing of diagrams in main Wiki page
  * decode DMSF error codes in something more understable


## v0.3.1 (2016-11-03)

### New

* Added dialogs for inserting macros. [Michele Tessaro]

* Added dialogs for inserting macros. [Michele Tessaro]

### Other

* Fixed saving if Redmine in subpath (closes #5) [Michele Tessaro]

  * fixed saving diagrams if Redmine is running in a sub path URL
  * fixed toolbar buttons switched


## v0.3.0 (2016-10-28)

### New

* Added dialogs for inserting macros. [Michele Tessaro]


## v0.2.0 (2016-11-01)

### New

* Added drawio_attach macro. [Michele Tessaro]

* Added drawio_dmsf macro. [Michele Tessaro]

  This macro can draw diagrams from DMSF documents.
  The diagram editor is launched embedded, by a double click on the
  diagram.

### Fix

* Fixed rendering of some graphs (fixes #2) [Michele Tessaro]

  Corrected javascript inclusion from http://www.draw.io so the diagrams
  can be correctly drawn.

* Fixed rendering of some graphs (like flowcharts) [Michele Tessaro]

* Fixed missing end of module. [Michele Tessaro]

* Fixed resource include from draw.io (refs #2) [Michele Tessaro]

  Corrected javascript inclusion from http://www.draw.io so the diagrams
  can be correctly drawn.


## v0.1.3 (2016-10-13)

### Fix

* Fixed rendering of some graphs (fixes #2) [Michele Tessaro]

  Corrected javascript inclusion from http://www.draw.io so the diagrams
  can be correctly drawn.


## v0.1.2 (2016-09-14)

### New

* Tested with Redmine v3.3.0 (closes #1) [Michele Tessaro]

### Fix

* Fixed internal plugin version. [Michele Tessaro]


## v0.1.1 (2016-08-02)

### New

* Added CHANGELOG.md. [Michele Tessaro]

  Changelog automatically generated thanks to
  [gitchangelog](https://github.com/vaab/gitchangelog) script.

### Fix

* Fixed conflict with the redmine_lightbox2 plugin. [Michele Tessaro]

### Other

* Added file to ignore. [Michele Tessaro]


## v0.1.0 (2016-07-30)

### Other

* Initial commit. [Michele Tessaro]

  First working release

* Initial commit. [Michele Tessaro]


