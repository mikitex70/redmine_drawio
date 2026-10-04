# AGENTS.md — redmine_drawio

Redmine plugin (`mikitex70/redmine_drawio`) that embeds draw.io diagrams in wiki pages,
issues and journals. It is **not** a standalone app: there is no Gemfile, Rakefile,
package.json, linter or CI in this repo. Everything runs inside a Redmine installation.

## Layout

| Path | Role |
|---|---|
| `init.rb` | Plugin registration. **Sole source of truth for `version`.** Loads `after_init.rb` only when `easy_extensions` is absent (EasyRedmine disables the plugin). |
| `after_init.rb` → `lib/redmine_drawio.rb` | Explicit require list (patches → helpers → hooks → macros). New top-level file must be added here. |
| `lib/redmine_drawio/macros.rb` | `drawio_attach` + `drawio_dmsf` macros, SVG sanitizing (`adaptSvg`), HTML encoders, DMSF path/version logic. The core of the plugin. |
| `lib/redmine_drawio/hooks/view_hooks.rb` | Injects CSS/JS into `<head>`, injects `Drawio.settings`, issues the REST API token (`hash_code`). |
| `lib/redmine_drawio/api_token.rb` | `RedmineDrawio::ApiToken` — signed, expiring token identifying the current user. The REST API key never reaches the browser. |
| `lib/redmine_drawio/patches/dmsf_webdav_controller_patch.rb` | Accepts the token on `/dmsf/webdav`, a Rack/Dav4rack middleware that never reaches `ApplicationController`. Ships two variants because DMSF 3.x (Redmine ≤ 5) enters auth via `#authenticate` and 4+/5.x via `#authenticate?`; `patch_dmsf_webdav` prepends the right one. |
| `lib/redmine_drawio/{helpers,patches}/` | `prepend` patches onto Redmine core + `heads_for_wiki_formatter` overrides for the jsToolbar. |
| `app/models/drawio_settings.rb` | Reads `Setting.plugin_redmine_drawio`. |
| `assets/javascripts/` | `drawioEditor.js` (embed iframe + save flow), `drawio_jstoolbar.js` (textile/Markdown toolbar), `drawio_plugin.js` (CKEditor plugin). `encoding*.js` are **vendored third-party** — do not edit. |
| `assets/javascripts/lang/`, `config/locales/` | JS strings vs Rails i18n — two separate sets, see below. |
| `spec/` | **Not test-only.** `spec/defaultImage.{png,svg,xml,drawio}` are the runtime placeholder diagrams, loaded by `Macros.imagePath`. `spec/files/` holds the XSS fixture used by the system spec. |
| `embed2js.patch` | Patch for building a *private draw.io war* (upstream repo), unrelated to this plugin's build. |

## Commands

No runner here — run from the Redmine root, with this repo checked out at
`<redmine>/plugins/redmine_drawio/`:

```bash
# Minitest (test/unit, test/integration)
bundle exec rake redmine:plugins:test NAME=redmine_drawio RAILS_ENV=test
bundle exec rake redmine:plugins:test:units NAME=redmine_drawio RAILS_ENV=test
bundle exec rake redmine:plugins:test:integration NAME=redmine_drawio RAILS_ENV=test

# Single file / single test
bundle exec ruby -Itest plugins/redmine_drawio/test/unit/drawio_settings_test.rb RAILS_ENV=test

# RSpec system spec (Capybara + real browser)
bundle exec rspec plugins/redmine_drawio/spec/system/cross_site_scripting_spec.rb RAILS_ENV=test

# Regenerate CHANGELOG.md (needs gitchangelog + pystache; both installed)
gitchangelog > CHANGELOG.md
```

- `:units`/`:integration` depend on `db:test:prepare`, so the test DB must exist.
- `test/test_helper.rb` reaches Redmine's helper via `../../../test/test_helper`, and the
  system spec hardcodes `plugins/redmine_drawio/spec/files` — **the checkout directory
  must be named `redmine_drawio` inside `plugins/`** or the specs break.
- `test/` and `spec/system/` use different harnesses (Minitest vs RSpec). Don't merge them.
- The DMSF unit/integration tests skip unless the environment has a working DMSF WebDAV
  endpoint: the unit test stops on `Redmine::Plugin.installed?(:redmine_dmsf)`, the
  integration one probes `/dmsf/webdav`. They need the DMSF tables plus
  `Setting.plugin_redmine_dmsf['dmsf_webdav']`, which `test/with_webdav_settings.rb`
  enables only inside each test (calling `Setting.clear_cache` after would drop it).

## Conventions that differ from the Ruby/Rails default

- **Branches**: work on `develop`; `master` is releases only (README *Contributing*).
- **Commit messages are parsed by gitchangelog** (`.gitchangelog.rc`) into `CHANGELOG.md`:
  `action: audience: message`, action ∈ `chg|fix|new`, audience ∈ `dev|usr|pkg|test|doc`.
  Examples: `fix: usr: fixed SVG diagrams (fixes #155)`, `chg: pkg: updated version`.
  Plain sentences fall into an "Other" section — follow the format.
- **Release** = bump `version` in `init.rb`, commit as `chg: pkg: ...`, tag `vX.Y.Z`,
  regenerate `CHANGELOG.md`. The `vX.Y.Z` tag regexp is what `gitchangelog` keys on.
- Core classes are patched with `Module#prepend` only. **Never** `alias_method_chain`;
  it breaks on Rails 5+ (see `helpers/textile_helper.rb`).
- Version guards are explicit and load-bearing: `Redmine::VERSION::MAJOR < 6` skips the
  Markdown formatter (gone in RM 6), `Rails::VERSION::STRING < '5.0.0'` switches
  aliasing vs prepend. Keep them when touching helpers.
- Plugin supports Redmine 2.6 → 7.x; the automated suites cover 5.1, 6.1 and 7.1, so avoid
  modern Ruby/Rails-only APIs and guard anything version-sensitive.
- No linter/formatter configured. `lib/redmine_drawio/macros.rb` uses 4-space nesting and
  legacy hash syntax; newer files use `# frozen_string_literal: true`. Match the file you
  are in — do not reformat legacy files.

## How a diagram round-trip works (non-obvious)

1. Macro renders HTML: `<img>` with base64 data URI (png/svg) or a
   `<div class="mxgraph" data-mxgraph="{...}">` (xml), plus an `ondblclick="editDiagram(...)"`.
2. `editDiagram` opens an iframe to `Drawio.settings.drawioUrl` (default
   `//embed.diagrams.net`) in draw.io embed mode and communicates via `postMessage`.
3. On save the **browser** persists, not the server:
   - attachments → `POST uploads.json`, then `GET`/`PUT <page>.json` to rewrite the macro
     reference in the wiki page / issue description / latest journal;
   - DMSF → `PUT dmsf/webdav/<path>`.
4. Auth uses `X-Redmine-Drawio-Token`, a signed, 15-min-expiring token identifying
   `User.current` (`RedmineDrawio::ApiToken`, built by `ViewHooks#hash_code`, sent by
   `authHeaders()` in `drawioEditor.js`). It is accepted in two places:
   - REST API: `ApplicationControllerPatch#find_current_user`, **only** where the API key
     would be (REST API enabled, `.json`/`.xml` request, action open to API auth), so it
     grants exactly the rights of the API key of its owner;
   - DMSF WebDAV: `DmsfWebdavControllerPatch`, before Dav4rack's Basic/Digest gets a
     chance to reject the request (`/dmsf/webdav` never reaches `ApplicationController`).
   The API key itself is never sent to the browser and cannot be recovered from the page:
   an encrypted blob is useless there, since only the server can decrypt it (this is why
   commit `d5880ab` broke the editor). Redmine's REST API **must be enabled** — hence the
   admin warning partial — and that also gates DMSF saving: `hash_code` returns an empty
   token when the API is off, so the WebDAV save gets a 401 just like the REST one.
   Because the token is minted when the page is rendered, a page left open longer than
   `ApiToken::TTL` gets a 401 on save.
5. `config/routes.rb` is intentionally empty — the plugin defines **no HTTP endpoints**.
6. `.json` requests never use the session cookie: `ApplicationController#find_current_user`
   skips `session[:user_id]` when `api_request?` (format `json`/`xml`). That is why the
   browser needs a credential at all, and why session auth is not an option here.

## Gotchas

- **SVG is sanitized twice, deliberately**: `adaptSvg` strips `<script>`, `on*` handlers
  and `javascript:` URLs; when the `drawio_svg_enabled` setting is off the SVG is rendered
  as a base64 `<img>` (no hyperlinks). Keep both paths in mind when changing rendering —
  `test/unit/lib/redmine_drawio/adapt_svg_test.rb` guards the sanitizer.
- **Attachment saving is version-suffixed** (`name_1.png`, `name_2.png`, …) because
  Redmine's API cannot update or delete attachments. Both the macro (`saveName`) and the
  JS regexes in `saveAttachment` must agree on the `_N` pattern.
- **Assets cache**: on Redmine ≤ 4.2 plugin assets are *mirrored* into
  `public/plugin_assets/redmine_drawio` at boot — delete that directory after editing JS/CSS
  or changes appear to do nothing. Redmine 5+ serves them via sprockets instead.
- **Adding a language** requires two files: `config/locales/<lang>.yml` (Rails) and
  `assets/javascripts/lang/drawio_jstoolbar-<lang>.js` (JS strings, assigned to
  `Drawio.strings[...]`). `ViewHooks#lang_supported?` decides by file existence, and
  `drawio_jstoolbar-en.js` is always loaded first. These sets are already out of sync
  (`ko.yml` has no JS counterpart).
- **DMSF is optional**: the macro, helper and tests are all behind
  `Redmine::Plugin.installed?(:redmine_dmsf)`; DMSF path layout is version-dependent
  (`Macros.dmsf_save_name`), as is the WebDAV auth entry point: `#authenticate` on DMSF 3.x,
  `#authenticate?` on 4+/5.x (see `DmsfWebdavControllerPatch`). Keep the guards so the
  plugin loads without DMSF.
- PDF export works by rendering images, not by running the XML viewer
  (`Macros.pdf?` + `RbpdfPatch` resolving attachment URLs).

## Known rough edges (verified — don't assume they work)

- `Macros.js_safe` (`macros.rb:493`) discards its `gsub` result and always returns `''`,
  so the "page name" argument passed into JS is always empty.
- `drawioEditor.js` reads `Drawio.strings['drawio_save_error']`, but every
  `drawio_jstoolbar-*.js` defines `drawiosave_error` — that alert message is `undefined`.
- Zoom option spelling differs per macro: `drawio_attach` uses `initialzoom`,
  `drawio_dmsf` uses `initialZoom`.
- MathJax support was removed (draw.io ≥ 10.7.4 bundles it), but `DrawioSettings.mathjax_url`,
  the `drawio_mathjax*` locale keys, `assets/javascripts/drawio_settings.js` (loaded
  nowhere) and the README's *Local MathJax installation* section are all leftovers.
