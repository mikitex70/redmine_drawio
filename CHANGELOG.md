# Changelog


## development (unreleased)

### v1.4.5 (2022-12-09)

* Fix mail sending error. [Hunt Lin]


## v1.4.4 (2022-09-13)

### Changes

* Updated the changelog. [Michele Tessaro]

* Changed version for the new release. [Michele Tessaro]

### Fix

* Fixed working on Redmine < 5 (refs #121) [Michele Tessaro]

* Fixed init of multiple tinymce editors (refs #119) [Michele Tessaro]

  Refactored the TinyMCE editor inizialization detection for adding the
  toolbar buttons; now it works also for issue notes.
  Fixed also some trouble in inserting macro code after editing.

* Fixed patching of viewer-static.min.js (refs #120) [Michele Tessaro]

  The code in `viewer-static.min.js` from `embed.diagrams.net` was
  refactored, so the patch code had to be adapted.

* Reduced polling timeout on tinymce initialization (refs #119) [Michele Tessaro]


## v1.4.3 (2022-09-07)

### Changes

* Updated changelog. [Michele Tessaro]

* Updated the changelog for the new release. [Michele Tessaro]

### Fix

* Fixed toolbar buttons with the WYSIWYG plugin (refs #119) [Michele Tessaro]

* Fixes broken tests. [Liane Hampe]

  There were code changes causing tests to fail.

* Fixes typo in de.yml. [Liane Hampe]

### Other

* Removes unused instance var from test. [Liane Hampe]

* Adds namespaces to tests. [Liane Hampe]

  In order to prevent class clashes all test are wrapped with
  module 'RedmineDrawio'.


## v1.4.2 (2022-07-16)

### Changes

* Updated the changelog for the new release. [Michele Tessaro]

* Update README.md. [sstidl]

  typo

* Viewer.js: Use drawio_service_url if configured. [sstidl]

  it would reduce the dependency to diagrams.net if we use the viewer from our own instance

* Mathjax bumped to 2.7.7. [Michele Tessaro]

* Added paragraph on dmsf webdav configuration. [Michele Tessaro]

* Updated documentation with mention on pdf export. [Michele Tessaro]

### Fix

* Fix #55 redmine attachments patch redmine/redmine@e551c0cb0092088510c66dea3e8bcaf87f93c08e. [krutin]

* Fix #55 macro body for pdf format return src url. [krutin]


## v1.4.1 (2022-06-18)

### New

* Added more german translations (refs #111, thanks to Liaham) [Michele Tessaro]

### Fix

* Fixed possible XSS (fixes #111, thanks to Liaham) [Michele Tessaro]


## v1.4.0 (2022-05-20)

### New

* Support Redmine 5.0 (refs #110) [sk-ys]

### Changes

* Updated documentation for the new release. [Michele Tessaro]


## v1.3.1 (2022-05-14)

### Changes

* Updated changelog. [Michele Tessaro]

### Fix

* Fixed mxgraph viewer patch (refs #105) [Michele Tessaro]

  Fixed the patch of the viewer of diagrams in XML format, caused by a
  recent change in the Drawio scripts.

### Other

* Fixed check for api enabled. [Liane Hampe]

  ViewLayoutsBaseHtmlHeadHook#hash_code uses a wrong api enabled check which
  would not return true if rest api is enabled.

* Fixed generating api key even if api not enabeld. [Liane Hampe]

  When the api is not enabled there should be no api key requested
  for the current user. Moreover, Redmine
  MyControllerTest#test_reset_api_key_without_existing_key
  would fail since it does not expect the current user to have an api key by
  default.

  Added a warning for the admin if api is disabled since the plugin needs
  the api for saving diagrams as attachment.


## v1.3.0 (2022-02-19)

### Changes

* Updated CHANGELOG.md for the new release. [Michele Tessaro]

* Def: updated version for the new release. [Michele Tessaro]

* Updates.gitignore. [Liane Hampe]

  Adds .history what is a vs code extension storing the history of all
  changes.

### Fix

* Fixes usage of drawio_svg_enabled setting. [Liane Hampe]

  If svg is disabled the corresponding checkbox
  in _marcro_dialog.html.erb won't be displayed anymore.

  Adds tests for this fix and a check for the settings table.
  The table check is necessary for running tests since the table is not
  available when loading the code.


## v1.2.1 (2022-01-05)

### Fix

* Fixed use of diagrams in XML format (fixes #105) [Michele Tessaro]

  Bug introduced by a change in an external Javascript from
  `embed.diagrams.net`.

* Updated documentation. [Michele Tessaro]


## v1.2.0 (2021-11-24)

### Changes

* Updated documentation for the new release. [Michele Tessaro]

### Fix

* Added setting to choose svg implementation (refs #102) [Michele Tessaro]

  Added a plugin setting to choose how svg images are displayed:
  * if svg is disabled, they are rendered as a base64 svg (hyperlinks not
    working)
  * if svg is enabled, they are rendered as inline svg, but they are
    vulnerable to XSS issues (mitigated, but not eliminated)

* Prevent XSS from SVG. [Mauryl Dovand]

* Fixed more svg XSS issues (refs #102) [Michele Tessaro]


## v1.1.4 (2021-09-26)

### New

* Added wiki page comment on attachment update (refs #100) [Michele Tessaro]

  By updating a diagram attached to a wiki page, a comment will be added to the
  page history.

### Fix

* Fixed XSS security problems with svg diagrams (fixes #102) [Michele Tessaro]


## v1.1.3 (2021-08-26)

### Changes

* Updated changelog for the new release. [Michele Tessaro]

### Fix

* Fixed diagrams in issues (fixes #99) [Michele Tessaro]


## v1.1.2 (2021-08-19)

### Changes

* Updated changelog for the new release. [Michele Tessaro]

### Fix

* Fixed wiki page with single quotes (fixes #98) [Michele Tessaro]


## v1.1.1 (2021-07-16)

### Changes

* Updated changelog for the new release. [Michele Tessaro]

### Fix

* Fixed xml diagram viewer patch (refs #96) [Michele Tessaro]

  The dynamic patch of the `viewer-static.min.js` was broken due to an
  update of the library.
  Now the dynamic patch should be more robust.


## v1.1.0 (2021-06-18)

### New

* Enabled use of drawio libraries (implements #95) [Michele Tessaro]


## v1.0.3 (2021-05-26)

### New

* Added configuration section on CSP headers. [Michele Tessaro]

### Changes

* Update CHANGELOG.md. [Michele Tessaro]

### Fix

* Fixed save on null journal notes (refs #93) [Michele Tessaro]


## v1.0.2 (2021-05-13)

### Changes

* Updated CHANGELOG.md. [Michele Tessaro]

### Fix

* Fixed use of special chars as page name (fixes #92) [Michele Tessaro]

  The use of special characters (like `+`) in the name of a wiki page was
  causing am HTTP 404 during diagram save as attachment.

* Fixed use of single quote in image name (fixes #91) [Michele Tessaro]


## v1.0.1 (2021-03-23)

### Fix

* Fixed missing javascript file (refs #89) [Michele Tessaro]

  The file `encoding.min.js` was not added in the last commit.

* Fixed release in the CHANGELOG. [Michele Tessaro]


## v1.0.0 (2021-02-21)

### New

* Added page and layer selector for XML diagrams (refs #86) [Michele Tessaro]

* Fixed patch for building draw.io server (fixes #81) [Michele Tessaro]

### Changes

* Updated CHANGELOG for the new release. [Michele Tessaro]

* Updated README for the new release. [Michele Tessaro]

* Updated CHANGELOG. [Michele Tessaro]

### Fix

* Fixed save on recents dmsf (refs #87) [Michele Tessaro]

* Fixed wrong url hint in config dialog. [Michele Tessaro]


## v0.9.9 (2020-12-19)

### New

* Support german. [Andreas Hunholz]


## v0.9.8 (2020-11-19)

### New

* Updated README to highlight need to enable of REST API. [Michele Tessaro]

  Highlighted the need to enable the REST API for the usage of the
  `drawio_attach` macro, as it seems it isn't enough visible.

* Support Japanese. [sk-ys]

### Fix

* Fixed stupidly forgotten commented code. [Michele Tessaro]


## v0.9.7 (2020-09-24)

### Fix

* Updated drawio url (fixes #80) [Michele Tessaro]


## v0.9.6 (2020-06-21)

### Fix

* Fixed header/footer dup with Wiki Extensions (fixes #79) [Michele Tessaro]

  With the Wiki Extensions plugin the header and footer fragments were
  duplicated everytime a diagram attachment was changed.


## v0.9.5 (2020-05-04)

### Fix

* Fixed saving diagram attachments in issues (fixes #77) [Michele Tessaro]


## v0.9.4 (2020-05-03)

### Fix

* Fixed save attachments on main wiki page (fixes #76) [Michele Tessaro]

  Saving diagrams as attachments on main wiki page was failing cause a
  *page not found* error.
  Main wiki page url does not contain the wiki page name, which must be
  explicitly used when saving.


## v0.9.3 (2020-02-10)

### New

* Initial Korean tanslation. [Ji-Hyeon Gim]


## v0.9.2 (2020-01-10)

### Changes

* Updated documentation. [Michele Tessaro]

### Fix

* Fixed ajax header in saving attachments (refs #72) [Michele Tessaro]


## v0.9.1 (2020-01-06)

### Fix

* Fixed saving of empty diagrams (fixes #67) [Michele Tessaro]

  When saving and empty diagram there will be no image to click on the
  page, so the diagram cannot be modified anymore.
  This fix will detect these situations and block savings of empty
  diagrams.


## v0.9.0 (2019-08-03)

### New

* Added integration with `redmine_wysiwyg_editor` (refs #69) [Michele Tessaro]

  Now the drawio editor buttons appears also in the toolbar of the
  `redmine_wysiwyg_editor`.

### Changes

* Updated documentation for the new release. [Michele Tessaro]

* Upgraded MathJax at version 2.7.5. [Michele Tessaro]

### Fix

* Load MathJax through CDN if custom url is an empty string. [Vincent Robert]


## v0.8.5 (2019-06-15)

### Changes

* Updated CHANGELOG for the new release. [Michele Tessaro]

### Fix

* Fixed incompatibility with Redmine 4/ Rails 5 (fixes #66) [Michele Tessaro]


## v0.8.4 (2019-05-25)

### Changes

* Updated changelog for the new release. [Michele Tessaro]

### Fix

* Make regex case-insensitive. [Vincent Robert]

### Other

* Use last edited diagram if several have an identical name. [Vincent Robert]


## v0.8.3 (2018-10-27)

### Fix

* Fixed conflict with `redmine_wiki_extensions` (fixes #60) [Michele Tessaro]

  Fixed `fnlist` macro duplication when the `drawio_attach` macro is used
  and the `redmine_wiki_extensions` plugin is installed.


## v0.8.2 (2018-05-01)

### Changes

* Updated changelog. [Michele Tessaro]

### Fix

* Fixed mathjax configuration url always disabled (refs #56) [Michele Tessaro]

* Fixed saving with DMSF 1.6.1+ (refs #32) [Michele Tessaro]

  DMSF 1.6.1 has changed the webdav path used to access documents.

* Fixed attachment saving with restricted extensions (fixes #54) [Michele Tessaro]

  If in Redmine the file attachment `Allowed extensions` is set, the
  saving fails with an error `Attachment extensions  is not allowed`, even
  if the diagram estension is correct.


## v0.8.1 (2018-02-24)

### New

* Added Danish translation. [Anders Thomsen]

* Added traditional chinese translation. [Nickle]

* Added markdown editor support (refs #49) [Michele Tessaro]

  Added in the markdown editor the buttons for inserting macros.

* Local MathJax installation support (refs #46) [Michele Tessaro]

  The MathJax Javascript library can now be referenced from a local
  installation to avoid downloading it from Internet.

### Changes

* Updated change log. [Michele Tessaro]

* Updated documentation. [Michele Tessaro]

* Updated documentation. [Michele Tessaro]

### Fix

* Fixed SVG saving in DMSF (refs #51) [Michele Tessaro]

* Fixed working with rails 5 (fixes #44) [Michele Tessaro]

* Fix bug while saving diagram on page with non-ascii name. [Anton Sergeev]

  Fixed generating wrong URL when trying update attachments on a page.
  This bug occurs on wiki-page that has pageName with non-ascii characters.

* Fixed https access to the drawio site (fixes #41) [Michele Tessaro]

  Fixed a wrongly disabled https protocol when calling the www.draw.io
  site, which caused security problems with modern browsers.


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

  Fixed saving on DMSF 1.5.9+ when "Use project name for project folder"
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

* Fix #27: Javascript error match on undefined. [Alexander Menk]

  Prevented saving in EasyRedmine issue note

* Fix #27: Javascript error match on undefined. [Alexander Menk]

  Prevented saving in EasyRedmine issue note

* Fixed updating diagrams on private notes (fixes #28) [Michele Tessaro]

* Fixed saving of SVGs (fixes #26, #26) [Michele Tessaro]

* Fixed SVG corrupted after save before reload (fixes #25) [Michele Tessaro]

  After editing an SVG diagram and saving it, double clicking on the
  diagram without reloading page causes an `Not a diagram` error in the
  drawio diagram editor.
  Seems that updating the SVG in the page causes the insertion of an
  `"=""' text, that confuses the parser.
  Removed with an regex, but not identified the source problem (maybe
  related to the `XMLSerializer` Firefox browser object).

* Fixed macros after refactor for easyredmine (refs #18) [Michele Tessaro]

* Fixed macros after refactor for easyredmine (refs #18) [Michele Tessaro]


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
  drawio_attach macro, that caused "Not found" errors.


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


