# AGENTS.md – goblin-converter.cr

Crystal + GTK4/Adwaita document converter. Conversion shells out to ImageMagick `magick` (+ Ghostscript for PDFs).

Target platforms: Linux (primary/dev) and Windows. macOS is not planned.

Repo language is English — keep code, comments, docs, and commit messages in English.

## Commands
- Setup: `shards install` (creates git-ignored `lib/`)
- Build: `make build` (= `crystal build src/goblin-converter.cr -o bin/goblin-converter`)
- Run (needs display + `magick`): `make run`
- Format check: `crystal tool format --check src/` / fix with `crystal tool format src/`
- Install: `make install` (prefix `/usr/local`, app data copied to `/usr/local/share/goblin-converter` incl. `src/`, `po/`, `data/`, `shard.yml`)
- Uninstall / clean: `make uninstall` / `make clean`
- Tests: headless specs via `make test` (= `crystal spec`; note: there is no `crystal test` command). GUI code is untestable headless — keep new logic in pure `GoblinApp.*` helpers in `src/modules/functions/conversion_logic.cr` and cover them in `spec/`. Specs must never instantiate GTK widgets.

## Deps
- Crystal 1.20+ (shard.yml says >=1.10, README dev requirement is 1.20+).
- Arch: `sudo pacman -S base-devel crystal gtk4 libadwaita imagemagick ghostscript gettext`
- Ubuntu apt line in README.md. Runtime needs `magick` (IM7) + `gs` 10 + gettext tools (`msgfmt`, `xgettext`, `msgmerge`).

## Architecture
- Entry `src/goblin-converter.cr` → `GoblinApp::App < Adw::Application` → `MainWindow` in `src/modules/views/main_window.cr`.
- `MainWindow` is reopened across `src/modules/views/*.cr` (`class MainWindow`); each `create_*_group(vbox)` builds one UI section. State lives in `ConversionOptions`/`FormData` structs in `main_window.cr`.
- Convert logic only in `src/modules/views/convert_button_group.cr:start_conversion`: runs `magick` via `Gio::SubprocessLauncher` (argv, no shell) with stdout/stderr redirected to tempfiles, polls completion with raw `waitpid(WNOHANG)` from a `GLib.timeout` (ECHILD means GLib's child watch reaped it → ask `proc.successful`). On Windows (`{% if flag?(:win32) %}`) there is no waitpid and File fds aren't C ints: stdio is inherited and completion comes via patched `wait_check_async` (see `subprocess_patch.cr`); exit-status helpers in `conversion_logic.cr` have trivial win32 branches.
- Windows notes: no cross-compile from Linux — build must run on a Windows machine; win32 code paths can't be spec'd headless on Linux, verify them via `crystal build --cross-compile --target x86_64-windows-msvc -o /tmp/goblin-win src/goblin-converter.cr` (typecheck + codegen, skips link) plus testing on Windows. `make install` is Unix-only.
- Drag & drop delivers `GObject::Value`, never `Gdk::FileList`: unwrap via `LibGObject.g_value_get_boxed` + type check (see `dropped_file_path`), return `false` when unhandled.
- Never use Crystal `Thread`/`spawn`/`Channel` or `Process` with pipe-like redirects (`IO::Memory`, `Redirect::Pipe`) for subprocesses: fibers don't run while GTK blocks the main thread, and `Process` waiting hangs on worker threads (proven via headless harness). `Process.quote` as a pure string helper is fine.
- Dialogs: `src/modules/functions/dialogs.cr`; file picker: `open_file_dialog.cr`.
- `src/modules/prerequisites.cr`: `VERSION` via `read_file("./shard.yml")` macro — bump version only in `shard.yml`; Gettext domain `de.magynhard.GoblinConverter` with path relative to `po/`.

## i18n
- `make locales` after every `.po` change (compiles `.po` → `.mo` via `msgfmt` for langs in `po/LINGUAS`).
- `make generate_locales` only when translatable strings were added/removed (uses `po/POTFILES` → `.pot` via `xgettext`, then `msgmerge`/`msginit`). Missing from `.PHONY` but works.
- New source files with `_()`/`translate()` must be added to `po/POTFILES`; new languages to `po/LINGUAS`.

## Gotchas
- GUI app: `make run` fails headless without display.
- `lib/`, `bin/`, `*.mo`, `*.gresource`, `shard.lock` are git-ignored — do not commit.
- Release per README: version in `shard.yml` → `git tag X.Y.Z` → `git push origin X.Y.Z`.
