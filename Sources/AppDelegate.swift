import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var pollTimer: Timer?
    private var lastChangeCount = 0

    let model = ClipboardModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.imagePosition = .imageLeading
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 440)
        popover.behavior = .transient

        let holder = AppStateHolder(appDelegate: self)
        let rootView = MenuBarView(model: model) { [weak self] action in
            self?.handle(action)
        }.environmentObject(holder)

        popover.contentViewController = NSHostingController(rootView: rootView)

        statusItem.button?.action = #selector(togglePopover(_:))

        lastChangeCount = NSPasteboard.general.changeCount
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
    }

    enum Action {
        case copy(Clip)
        case pin(Clip)
        case unpin(Clip)
        case delete(Clip)
        case clear
        case clearPinned
    }

    private func handle(_ action: Action) {
        switch action {
        case .copy(let clip):
            copyToPasteboard(clip.text)
            popover.performClose(nil)
        case .pin(let clip):
            togglePin(clip)
        case .unpin(let clip):
            togglePin(clip)
        case .delete(let clip):
            delete(clip)
        case .clear:
            model.clips = model.clips.filter { $0.pinned }
        case .clearPinned:
            model.clips = model.clips.filter { !$0.pinned }
        }
    }

    private func togglePin(_ clip: Clip) {
        guard let idx = model.clips.firstIndex(where: { $0.id == clip.id }) else { return }
        model.clips[idx].pinned.toggle()
        reorder()
    }

    private func delete(_ clip: Clip) {
        model.clips.removeAll { $0.id == clip.id }
    }

    private func reorder() {
        model.clips.sort { a, b in
            if a.pinned != b.pinned { return a.pinned && !b.pinned }
            return a.date > b.date
        }
    }

    private func pollPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount

        guard let string = pb.string(forType: .string) else { return }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = model.clips.firstIndex(where: { $0.text == trimmed }) {
            model.clips.remove(at: existing)
        }

        model.clips.insert(Clip(text: trimmed), at: 0)
        if model.clips.count > model.maxClips {
            let pins = model.clips.filter { $0.pinned }
            if pins.isEmpty {
                model.clips = Array(model.clips.prefix(model.maxClips))
            }
        }
        reorder()
        refreshIcon()
    }

    private func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        lastChangeCount = pb.changeCount + 1
    }

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        let count = model.filteredClips.count
        button.toolTip = count == 0 ? "Clipboard empty" : "\(count) clip\(count == 1 ? "" : "s")"
    }

    @objc private func togglePopover(_ sender: Any?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}
