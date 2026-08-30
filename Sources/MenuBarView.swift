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
            dateFilterBar
            Divider()
            clipList
            Divider()
            footer
        }
        .frame(width: 300, height: 500)
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

    private var dateFilterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(model.dateFilter.isActive ? .accentColor : .secondary)
                Menu {
                    ForEach(DateFilterKind.allCases, id: \.self) { kind in
                        Button {
                            model.dateFilter.kind = kind
                        } label: {
                            if kind == model.dateFilter.kind {
                                Label(kind.title, systemImage: "checkmark")
                            } else {
                                Text(kind.title)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(model.dateFilter.kind.title)
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Spacer()

                if model.dateFilter.isActive {
                    Button {
                        model.dateFilter.kind = .all
                    } label: {
                        Text("Clear")
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
            }

            if model.dateFilter.displayingCustom {
                HStack(spacing: 8) {
                    DatePicker("", selection: $model.dateFilter.customStart, displayedComponents: .date)
                        .labelsHidden()
                    Text("–")
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $model.dateFilter.customEnd, displayedComponents: .date)
                        .labelsHidden()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var clipList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(Array(model.filteredClips.enumerated()), id: \.element.id) { index, clip in
                    ClipRow(clip: clip, isSelected: index == model.selectedIndex, action: action)
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
    var isSelected: Bool = false
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
                    if let image = clip.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if clip.pinned {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(clip.isImage ? "Image" : preview)
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
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.gray.opacity(0.10))
        )
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

struct CopiedToastView: View {
    let text: String
    var image: NSImage? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            Text(text)
                .font(.system(.body))
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .foregroundColor(.white)
    }
}
