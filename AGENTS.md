# AGENTS.md

Concise reference for AI coding agents and contributors working with this repo.
For human-facing docs see [README.md](./README.md).

## What this is

**ClipboardBar** — a tiny macOS menu bar app that records clipboard history
(text and images). Full product docs: [README.md](./README.md).

- Language: Swift (SwiftUI + AppKit)
- Platform: macOS 14.0+ (Sonoma+), Apple Silicon (arm64) only
- App type: menu bar utility (`LSUIElement` = no Dock icon)
- License: MIT

## Repository layout

```
Sources/
  ClipboardBarApp.swift    # @main App entry point
  AppDelegate.swift        # Status item, popover, pasteboard polling, hotkey
  ClipboardModel.swift     # Clip struct, DateFilter, observable model, persistence
  ClipboardBarIcon.swift   # Programmatic menu bar icon drawing
  MenuBarView.swift        # SwiftUI panel (list, search, date filter, footer)
Scripts/
  build.sh                 # Builds ClipboardBar.app (compile + icon + codesign)
  make_icon.swift          # Generates AppIcon.icns
```

## Build

Requires Xcode Command Line Tools (arm64 Mac):

```bash
./Scripts/build.sh
```

- Output: `ClipboardBar.app` in the repo root.
- Runs `swiftc` with `-target arm64-apple-macosx14.0 -parse-as-library` over the
  5 source files in `Sources/`.
- Generates `AppIcon.icns` (via `Scripts/make_icon.swift`) into
  `Contents/Resources/`, then ad-hoc codesigns the bundle.

No Xcode project, no CocoaPods/SPM dependencies, no tests.

## Install / run

Downloaders use the prebuilt app from a GitHub Release:

1. Unzip `ClipboardBar.zip` → `ClipboardBar.app`.
2. Move to `/Applications`.
3. First launch is **ad-hoc signed**, so macOS shows an "unverified developer"
   warning. App still works (right-click → Open → Open).

To run for development, after building: `open ClipboardBar.app`.

## Permissions the user may need to grant

- **Pasteboard access** — required to read copied text/images
  (System Settings → Privacy & Security).
- **Accessibility** — required ONLY for the global ⌘⇧V hotkey
  (`NSEvent.addGlobalMonitorForEvents`). The app works fully from the menu bar
  icon without this.

## Shortcuts / interaction

- **⌘⇧V** — open the panel from any app (needs Accessibility permission)
- **↑ / ↓** — move selection; **Enter** — copy selected clip; **Esc** — dismiss
- Clicking a clip also copies it back to the clipboard and shows a toast

## Data & persistence

- History (text + PNG image data + pinned flag) is JSON-encoded and saved to
  `UserDefaults` (key `savedClips`) on every change; reloaded on launch.
- Pinned clips are never evicted; unpinned clips older than 30 days are pruned
  at startup. Max clips defaults to 60 (in-memory cap).

## Key behaviors / gotchas

- Pasteboard is polled every 500ms comparing `NSPasteboard.changeCount`; the app
  ignores its own writes by recording the post-write changeCount (do not regress
  this — it prevents duplicate re-copies).
- Dedup: identical text re-copies move to the top; identical image data is deduped.
- Features: search, date-range filter (presets + custom), pin, clear (with
  confirmation), image thumbnails, persistent history, custom menu bar icon.
- The menu bar icon is drawn programmatically (see `ClipboardBarIcon.swift`),
  so there is no separate image asset to update.

## Contribution notes

- Keep the 5-source-file `swiftc` build working — it's the only build path.
- If you add a new `Sources/*.swift` file, add it to the `swiftc` line in
  `Scripts/build.sh`, or the app won't compile.
- No test suite exists yet; validate by running `./Scripts/build.sh` and
  launching the app.
