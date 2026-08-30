# ClipboardBar 📋

A tiny macOS **menu bar** app that keeps a history of everything you copy, so you
never lose a snippet again.

ClipboardBar sits quietly in the top-right of your screen as a clipboard icon.
Every time you copy text, it's captured automatically. Click the icon to browse
your recent clips, search for one, and paste it back with a single click — even
after you've copied a dozen other things in between.

No Dock icon, no setup. It just works.

> 🤖 **For AI agents & contributors:** see [AGENTS.md](./AGENTS.md) for a concise
> build / install / architecture reference.

---

## Quick start

- **Install:** download `ClipboardBar.zip` from the latest
  [release](https://github.com/danialjeffry/ClipboardBar/releases), extract,
  and move `ClipboardBar.app` to **Applications**.
- **Build:** `./Scripts/build.sh` → outputs `ClipboardBar.app`.
- **Use:** copy anything, then open the panel with the menu bar icon or **⌘⇧V**.

---

## Features

- **Automatic capture** — everything you copy (Cmd+C) is saved instantly.
- **History** — keeps your latest clips (up to 60), newest first.
- **Quick re-copy** — click any clip to put it right back on your clipboard.
- **Search** — filter your whole history by typing a few keywords.
- **Date filter** — narrow history by **All Time / Today / Yesterday / Last 7 /
  Last 30 days**, or pick a **custom start-to-end range**. Combines with search.
- **Pin important clips** — pinned items are kept safe and stay at the top, so
  they're never pushed out by newer copies.
- **Keyboard-first** — press **⌘⇧V** anywhere to open the panel, use **↑ / ↓** to
  select and **Enter** to copy, **Esc** to close — never leave the keyboard.
- **Image support** — screenshots and copied images are captured as thumbnails
  and can be re-copied too.
- **Persistent history** — your clips and pins survive app restarts.
- **Delete / Clear** — remove a single clip, unpin everything, or wipe the
  unpinned history.

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
2. Copy anything (text or image) anywhere on your Mac.
3. **Mouse:** click the icon to open ClipboardBar and see your history.
4. **Keyboard:** press **⌘⇧V** anywhere to open the panel instantly, use **↑ / ↓**
   to highlight a clip, **Enter** to copy it (and close), **Esc** to dismiss.
5. **Click a clip** (or press Enter on it) to copy it back to your clipboard, then
   paste wherever you need.
6. Use the **search box** to filter, the **📌 pin** to keep important clips safe,
   and **Clear** to start fresh. Everything is saved automatically.

> **Permissions:**
> - On first run, allow **pasteboard** access in **System Settings → Privacy &
>   Security** so ClipboardBar can read your copied text.
> - To use the global **⌘⇧V** hotkey, allow **Accessibility** access for
>   ClipboardBar in **System Settings → Privacy & Security → Accessibility**.
>   (The app still works fully with the menu bar icon if you skip this.)

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
last seen value. When it changes, ClipboardBar reads the new text or image data, dedupes
it against existing history, inserts it at the top, and trims the list down to a fixed
maximum.

Pinned clips are never evicted and are always sorted above unpinned ones. The history is
encoded to JSON and saved to `UserDefaults` on every change, then reloaded on launch, so
clips and pins survive restarts. Unpinned clips older than 30 days are pruned on startup.

For keyboard access, a global key monitor listens for **⌘⇧V** to pop the panel open from
any app, and a local monitor routes **↑ / ↓ / Enter / Esc** to move, copy, or dismiss.

---

## Notes

- **Ad-hoc signed** — suitable for personal use and sharing with friends; it isn't
  notarized for distribution through the Mac App Store.
- To distribute more widely, you'd want to add **Apple Developer notarization**, which
  removes the "unverified developer" warning.
