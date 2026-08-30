import AppKit
import Combine

struct Clip: Identifiable, Hashable, Codable {
    let id: UUID
    let text: String
    let imageData: Data?
    var pinned: Bool
    let date: Date

    init(id: UUID = UUID(), text: String = "", imageData: Data? = nil, pinned: Bool = false, date: Date = Date()) {
        self.id = id
        self.text = text
        self.imageData = imageData
        self.pinned = pinned
        self.date = date
    }

    var isImage: Bool { imageData != nil }

    var image: NSImage? {
        guard let imageData else { return nil }
        return NSImage(data: imageData)
    }
}

@MainActor
final class ClipboardModel: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var searchText = ""
    @Published var latestText = ""

    let maxClips = 60

    private let defaultsKey = "savedClips"

    init() {
        load()
    }

    var filteredClips: [Clip] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let list = clips
        guard !trimmed.isEmpty else { return list }
        return list.filter { clip in
            if clip.isImage { return "image".localizedCaseInsensitiveContains(trimmed) }
            return clip.text.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var selectedIndex = 0

    func save() {
        guard let data = try? JSONEncoder().encode(clips) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let saved = try? JSONDecoder().decode([Clip].self, from: data) else { return }
        clips = saved
    }

    func removeStaleClips() {
        let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        clips.removeAll { !$0.pinned && $0.date < cutoff }
    }
}

@MainActor
final class AppStateHolder: ObservableObject {
    weak var appDelegate: AppDelegate?
    init(appDelegate: AppDelegate?) {
        self.appDelegate = appDelegate
    }
}
