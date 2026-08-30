import SwiftUI
import AppKit

@MainActor
struct MenuBarView: View {
    @ObservedObject var model: ClipboardModel
    let action: (AppDelegate.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            searchBar
            Divider()
            clipList
            Divider()
            footer
        }
        .frame(width: 300, height: 460)
    }

    private var header: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .foregroundColor(.secondary)
            Text("Clipboard")
                .font(.headline)
            Spacer()
            Text("\(model.filteredClips.count) item\(model.filteredClips.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search clips…", text: $model.searchText)
                .textFieldStyle(.plain)
            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.15)))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var clipList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(model.filteredClips) { clip in
                    ClipRow(clip: clip, action: action)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .overlay {
            if model.filteredClips.isEmpty {
                emptyState
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(model.searchText.isEmpty ? "Nothing copied yet" : "No matches")
                .font(.callout)
                .foregroundColor(.secondary)
            Text("Copy any text to start building a history")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                action(.clearPinned)
            } label: {
                Label("Unpin All", systemImage: "pin.slash")
            }
            .disabled(!model.clips.contains { $0.pinned })

            Spacer()

            if !model.clips.isEmpty {
                Button(role: .destructive) {
                    action(.clear)
                } label: {
                    Label("Clear", systemImage: "trash")
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

@MainActor
struct ClipRow: View {
    let clip: Clip
    let action: (AppDelegate.Action) -> Void

    private var preview: String {
        let text = clip.text.replacingOccurrences(of: "\n", with: " ")
        if text.count > 90 {
            return String(text.prefix(90)) + "…"
        }
        return text
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                action(.copy(clip))
            } label: {
                HStack(spacing: 10) {
                    if clip.pinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preview)
                            .font(.system(.body))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(clip.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    action(clip.pinned ? .unpin(clip) : .pin(clip))
                } label: {
                    Label(clip.pinned ? "Unpin" : "Pin", systemImage: clip.pinned ? "pin.slash" : "pin")
                }
                Button(role: .destructive) {
                    action(.delete(clip))
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.10)))
        .contextMenu {
            Button {
                action(.copy(clip))
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button {
                action(clip.pinned ? .unpin(clip) : .pin(clip))
            } label: {
                Label(clip.pinned ? "Unpin" : "Pin", systemImage: clip.pinned ? "pin.slash" : "pin")
            }
            Divider()
            Button(role: .destructive) {
                action(.delete(clip))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
