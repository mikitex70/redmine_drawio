# Changelog

## development (unreleased)

### New

* Added configuration of draw.io server (implements #12) [Michele Tessaro]

  Added a configuration dialog which can be used to change the default URL
  of the draw.io server.
  Added also notes on how to build a fully functionally war file of the
  draw.io site (the default is missing of a servlet).

* Added support for issue notes. [Michele Tessaro]

### Fix

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

* Load 'loading' image using protocol-relative paths. [Javango]

  When loading the ajax-loader image from a https site I am getting the following error message,  this switches to protocol-relative paths.

  Mixed Content: The page at 'https://support.my-site.com/issues/9999' was loaded over HTTPS, but requested an insecure image 'http://www.draw.io/images/ajax-loader.gif'. This content should also be served over HTTPS.

* Fixed errors when used outside wiki pages (refs #9) [Michele Tessaro]

* Fixed redmine path with custom route (fixes #7) [Michele Tessaro]

  Fixed calculation of Redmine web path when using custom routes, such
  when using a single project as Redmine home page (see
  http://www.redmine.org/boards/2/topics/32811)

* Load 'loading' image using protocol-relative paths. [Javango]

  When loading the ajax-loader image from a https site I am getting the following error message,  this switches to protocol-relative paths.

  Mixed Content: The page at 'https://support.my-site.com/issues/9999' was loaded over HTTPS, but requested an insecure image 'http://www.draw.io/images/ajax-loader.gif'. This content should also be served over HTTPS.


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


