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

enum DateFilterKind: String, CaseIterable, Codable {
    case all
    case today
    case yesterday
    case last7
    case last30
    case custom

    var title: String {
        switch self {
        case .all: return "All Time"
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .last7: return "Last 7 Days"
        case .last30: return "Last 30 Days"
        case .custom: return "Custom Range"
        }
    }
}

struct DateFilter {
    var kind: DateFilterKind = .all
    var customStart: Date = Calendar.current.startOfDay(for: Date())
    var customEnd: Date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 3600)

    var isActive: Bool { kind != .all }

    var displayingCustom: Bool { kind == .custom }

    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.dateInterval(of: .day, for: date)
        switch kind {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .yesterday:
            return calendar.isDateInYesterday(date)
        case .last7:
            return date >= calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? date
        case .last30:
            return date >= calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: Date())) ?? date
        case .custom:
            guard let day else { return false }
            return day.start >= customStart && day.start < customEnd
        }
    }
}

@MainActor
final class ClipboardModel: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var searchText = ""
    @Published var dateFilter = DateFilter()
    @Published var latestText = ""

    let maxClips = 60

    private let defaultsKey = "savedClips"

    init() {
        load()
    }

    var filteredClips: [Clip] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return clips.filter { clip in
            if trimmed.isEmpty == false {
                if clip.isImage {
                    if !"image".localizedCaseInsensitiveContains(trimmed) { return false }
                } else if !clip.text.localizedCaseInsensitiveContains(trimmed) {
                    return false
                }
            }
            return dateFilter.matches(clip.date)
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
