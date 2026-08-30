import AppKit
import Combine

struct Clip: Identifiable, Hashable {
    let id: UUID
    let text: String
    var pinned: Bool
    let date: Date

    init(id: UUID = UUID(), text: String, pinned: Bool = false, date: Date = Date()) {
        self.id = id
        self.text = text
        self.pinned = pinned
        self.date = date
    }
}

@MainActor
final class ClipboardModel: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var searchText = ""
    @Published var latestText = ""

    let maxClips = 60

    var filteredClips: [Clip] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let list = clips
        guard !trimmed.isEmpty else { return list }
        return list.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
    }
}

@MainActor
final class AppStateHolder: ObservableObject {
    weak var appDelegate: AppDelegate?
    init(appDelegate: AppDelegate?) {
        self.appDelegate = appDelegate
    }
}
