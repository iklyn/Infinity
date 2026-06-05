import SwiftUI

struct TimerRowView: View {
    let item: TimerItem
    var onEdit: () -> Void = {}
    @EnvironmentObject var store: TimerStore

    @State private var hovered    = false
    @State private var renaming   = false
    @State private var draft      = ""
    @FocusState private var nameFocused: Bool

    private var d: TimeDisplay { TimeCalculator.display(for: item) }

    var body: some View {
        HStack(spacing: 13) {
            icon
            center
            Spacer(minLength: 8)
            value
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(hovered ? Color.white.opacity(0.04) : .clear)
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .contextMenu {
            Button("Rename") { startRename() }
            Button("Edit")   { onEdit() }
            Divider()
            Button("Delete", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    store.delete(item)
                }
            }
        }
    }

    // MARK: Icon + ring

    private var icon: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.06)).frame(width: 42, height: 42)
            if let p = d.progress, !d.isToday {
                Circle()
                    .trim(from: 0, to: p)
                    .stroke(Theme.accentGradient,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(-90))
            }
            Text(item.emoji).font(.system(size: 19))
        }
    }

    // MARK: Center (name + subtitle)

    private var center: some View {
        VStack(alignment: .leading, spacing: 3) {
            if renaming {
                TextField("Name", text: $draft)
                    .font(.onePlus(13)).foregroundColor(.white).textFieldStyle(.plain)
                    .focused($nameFocused)
                    .onSubmit(commitRename)
                    .onExitCommand(perform: cancelRename)
                    .onChange(of: nameFocused) { if !$0 { commitRename() } }
            } else {
                Text(item.name.isEmpty ? "Untitled" : item.name)
                    .font(.onePlus(14)).foregroundColor(.white).lineLimit(1)
                    .onTapGesture(count: 2, perform: startRename)
            }
            Text(d.subtitle)
                .font(.onePlus(10, .light)).foregroundColor(.white.opacity(0.4)).lineLimit(1)
        }
    }

    // MARK: Right value

    @ViewBuilder
    private var value: some View {
        if d.isToday {
            ZStack {
                Circle().stroke(Theme.accentGradient,
                                style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                    .frame(width: 32, height: 32)
                Image(systemName: "checkmark").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accentGradient)
            }
        } else if item.isCompleted {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    store.restart(item)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accentSolid)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Theme.accentSolid.opacity(0.18)))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Restart")
        } else {
            VStack(alignment: .trailing, spacing: 1) {
                Text(d.primary)
                    .font(.onePlus(26, .light)).foregroundColor(.white).monospacedDigit()
                if !d.unit.isEmpty {
                    Text(d.unit).font(.onePlus(9, .light)).foregroundColor(.white.opacity(0.4))
                }
            }
        }
    }

    // MARK: Rename

    private func startRename()  { draft = item.name; renaming = true; nameFocused = true }
    private func cancelRename() { renaming = false; nameFocused = false }
    private func commitRename() {
        let t = draft.trimmingCharacters(in: .whitespaces)
        if !t.isEmpty, t != item.name { var u = item; u.name = t; store.update(u) }
        renaming = false; nameFocused = false
    }
}
