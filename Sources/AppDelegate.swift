import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
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
        popover.delegate = self

        let holder = AppStateHolder(appDelegate: self)
        let rootView = MenuBarView(model: model) { [weak self] action in
            self?.handle(action)
        }.environmentObject(holder)

        popover.contentViewController = NSHostingController(rootView: rootView)

        statusItem.button?.action = #selector(togglePopover(_:))

        model.removeStaleClips()
        model.clips.sort { a, b in
            if a.pinned != b.pinned { return a.pinned && !b.pinned }
            return a.date > b.date
        }

        lastChangeCount = NSPasteboard.general.changeCount
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }

        setupGlobalHotkey()
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
            copyClip(clip)
            popover.performClose(nil)
            showCopiedToast(clip)
        case .pin(let clip):
            togglePin(clip)
        case .unpin(let clip):
            togglePin(clip)
        case .delete(let clip):
            delete(clip)
        case .clear:
            model.clips = model.clips.filter { $0.pinned }
            model.save()
        case .clearPinned:
            model.clips = model.clips.filter { !$0.pinned }
            model.save()
        }
    }

    private func togglePin(_ clip: Clip) {
        guard let idx = model.clips.firstIndex(where: { $0.id == clip.id }) else { return }
        model.clips[idx].pinned.toggle()
        reorder()
        model.save()
    }

    private func delete(_ clip: Clip) {
        model.clips.removeAll { $0.id == clip.id }
        model.save()
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

        if let string = pb.string(forType: .string) {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                if let existing = model.clips.firstIndex(where: { $0.text == trimmed && !$0.isImage }) {
                    model.clips.remove(at: existing)
                }
                insertClip(Clip(text: trimmed))
                return
            }
        }

        if let imageData = pasteboardImageData(pb), !imageData.isEmpty {
            if let existing = model.clips.firstIndex(where: { $0.imageData == imageData }) {
                model.clips.remove(at: existing)
            }
            insertClip(Clip(imageData: imageData))
        }
    }

    private func insertClip(_ clip: Clip) {
        model.clips.insert(clip, at: 0)
        if model.clips.count > model.maxClips {
            let pins = model.clips.filter { $0.pinned }
            if pins.isEmpty {
                model.clips = Array(model.clips.prefix(model.maxClips))
            }
        }
        reorder()
        refreshIcon()
        model.save()
    }

    private func pasteboardImageData(_ pb: NSPasteboard) -> Data? {
        if let png = pb.data(forType: .png) {
            return png
        }
        if let tiff = pb.data(forType: .tiff) {
            if let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                return png
            }
            return tiff
        }
        return nil
    }

    private func copyClip(_ clip: Clip) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if clip.isImage, let data = clip.imageData {
            pb.setData(data, forType: .png)
        } else {
            pb.setString(clip.text, forType: .string)
        }
        lastChangeCount = pb.changeCount
    }

    private func showCopiedToast(_ clip: Clip) {
        hideCopiedToast()

        let hosting: NSHostingController<CopiedToastView>
        if clip.isImage, let image = clip.image {
            hosting = NSHostingController(rootView: CopiedToastView(text: "Image copied", image: image))
        } else {
            let preview = clip.text.replacingOccurrences(of: "\n", with: " ")
            let short = preview.count > 40 ? String(preview.prefix(40)) + "…" : preview
            hosting = NSHostingController(rootView: CopiedToastView(text: short, image: nil))
        }

        let size = NSSize(width: 260, height: 56)
        hosting.view.frame = NSRect(origin: .zero, size: size)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: size.width, height: size.height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.contentViewController = hosting

        if let screen = NSScreen.main {
            let vx = screen.visibleFrame.midX - size.width / 2
            let vy = screen.visibleFrame.minY + 60
            panel.setFrameOrigin(NSPoint(x: vx, y: vy))
        }

        panel.orderFrontRegardless()
        copiedToastPanel = panel

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.hideCopiedToast()
        }
    }

    private var copiedToastPanel: NSPanel?

    private func hideCopiedToast() {
        copiedToastPanel?.orderOut(nil)
        copiedToastPanel = nil
    }

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        let count = model.filteredClips.count
        button.toolTip = count == 0 ? "Clipboard empty" : "\(count) clip\(count == 1 ? "" : "s")"
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
            onPopoverOpened()
        }
    }

    @objc private func showPopover() {
        guard !popover.isShown, let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        onPopoverOpened()
    }

    private func onPopoverOpened() {
        model.selectedIndex = 0
        model.searchText = ""
        installKeyMonitor()
    }

    private var keyMonitor: Any?

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, popover.isShown else { return event }
            if self.handleKey(event.keyCode, modifiers: event.modifierFlags, isRepeat: event.isARepeat) {
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    func popoverDidClose(_ notification: Notification) {
        removeKeyMonitor()
    }

    func handleKey(_ keyCode: UInt16, modifiers: NSEvent.ModifierFlags, isRepeat: Bool) -> Bool {
        guard popover.isShown else { return false }
        let list = model.filteredClips
        guard !list.isEmpty else { return false }

        let down = keyCode == 125
        let up = keyCode == 126
        let enter = keyCode == 36 || keyCode == 76
        let escape = keyCode == 53

        if up || down {
            let delta = down ? 1 : -1
            model.selectedIndex = min(max(model.selectedIndex + delta, 0), list.count - 1)
            return true
        }
        if enter {
            let clip = list[model.selectedIndex]
            handle(.copy(clip))
            return true
        }
        if escape {
            popover.performClose(nil)
            return true
        }
        return false
    }

    private func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if mods == [.command, .shift],
               event.keyCode == 9 {
                Task { @MainActor in
                    self?.showPopover()
                }
            }
        }
    }
}
