# ClipboardBar 📋

A tiny macOS **menu bar** app that keeps a history of everything you copy, so you
never lose a snippet again.

ClipboardBar sits quietly in the top-right of your screen as a clipboard icon.
Every time you copy text, it's captured automatically. Click the icon to browse
your recent clips, search for one, and paste it back with a single click — even
after you've copied a dozen other things in between.

No Dock icon, no setup. It just works.

---

## Features

- **Automatic capture** — everything you copy (Cmd+C) is saved instantly.
- **History** — keeps your latest clips (up to 60), newest first.
- **Quick re-copy** — click any clip to put it right back on your clipboard.
- **Search** — filter your whole history by typing a few keywords.
- **Pin important clips** — pinned items are kept safe and stay at the top, so
  they're never pushed out by newer copies.
- **Delete / Clear** — remove a single clip, unpin everything, or wipe the
  unpinned history.
- **Clipboard-only** — never touches files, images, or other formats; just text.

---

## Requirements

- macOS **14.0 (Sonoma)** or later
- An **Apple Silicon** Mac (M1/M2/M3/M4...) — the build script targets arm64.
- Xcode Command Line Tools (for building from source):
  ```bash
  xcode-select --install
  ```

---

## Install (pre-built app)

1. Extract `ClipboardBar.app` from the zip and drag it into your **Applications** folder.
2. First launch: because the app is ad-hoc signed (not from the App Store), macOS may
   warn that the developer can't be verified. **Right-click** (or Ctrl-click) the app →
   **Open** → **Open** again. This is only needed once.
3. (Optional) To auto-start at login: **System Settings → General → Login Items** → add `ClipboardBar`.

---

## Build from source

```bash
cd ClipboardBar
./Scripts/build.sh
```

This compiles the Swift sources and outputs `ClipboardBar.app` in the project root.

---

## Usage

1. Launch the app — you'll see the clipboard icon in the top-right menu bar.
2. Copy anything (text) anywhere on your Mac.
3. Click the icon to open ClipboardBar and see your history.
4. **Click a clip** to copy it back to your clipboard, then paste wherever you need.
5. Use the **search box** to find something specific, the **📌 pin** to keep
   important clips around, and **Clear** to start fresh.

> Note: On first run, if your Mac requests clipboard/pasteboard access in
> **System Settings → Privacy & Security**, allow it so ClipboardBar can read
> your copied text.

---

## Project structure

```
ClipboardBar/
├── Sources/                  # Swift source files
│   ├── ClipboardBarApp.swift # App entry point
│   ├── AppDelegate.swift     # Menu bar item, popover & pasteboard polling
│   ├── ClipboardModel.swift  # Clip model + observable state
│   └── MenuBarView.swift     # SwiftUI panel (list, search, pin/delete)
├── Scripts/
│   └── build.sh              # Build script (produces ClipboardBar.app)
├── .gitignore
├── LICENSE
└── README.md
```

---

## How it works

The app creates a menu bar item (`NSStatusItem`) with a popover containing a SwiftUI
panel. A lightweight 500ms timer compares `NSPasteboard.general.changeCount` against the
last seen value. When it changes, ClipboardBar reads the new text, dedupes it against
existing history, inserts it at the top, and trims the list down to a fixed maximum.

Pinned clips are never evicted and are always sorted above unpinned ones. Nothing is
written to disk in v1 — history is held in memory for the current session.

---

## Notes

- **Ad-hoc signed** — suitable for personal use and sharing with friends; it isn't
  notarized for distribution through the Mac App Store.
- **In-memory history** — clips don't persist across app restarts in v1.
- To distribute more widely, you'd want to add **Apple Developer notarization**, which
  removes the "unverified developer" warning.
