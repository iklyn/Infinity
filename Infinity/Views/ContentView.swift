import SwiftUI

// MARK: - Navigation

enum NavDest: Equatable {
    case list, add, settings
    case edit(TimerItem)

    static func == (l: NavDest, r: NavDest) -> Bool {
        switch (l, r) {
        case (.list, .list), (.add, .add), (.settings, .settings): return true
        case (.edit(let a), .edit(let b)): return a.id == b.id
        default: return false
        }
    }
    var isSecondary: Bool { self != .list }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var store: TimerStore
    @State private var nav: NavDest = .list

    private let rowHeight: CGFloat = 65
    private let maxListHeight: CGFloat = 520

    var body: some View {
        ZStack {
            if nav == .list {
                listScreen
                    .zIndex(1)
                    .transition(.move(edge: .leading))
            }
            if nav.isSecondary {
                secondary
                    .zIndex(2)
                    .transition(.move(edge: .trailing))
            }
        }
        .frame(width: 360)
        .background(Theme.bg)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: nav)
        .clipped()
        .overlay(alignment: .top) {
            if store.isAlarming { alarmBanner }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.isAlarming)
    }

    // MARK: Ringing banner

    private var alarmBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.fill")
                .font(.system(size: 13))
                .foregroundColor(Theme.bg)
            Text("Time's up")
                .font(.onePlus(13, .medium))
                .foregroundColor(Theme.bg)
            Spacer()
            Button { store.stopAlarm() } label: {
                Text("Stop")
                    .font(.onePlus(12, .medium))
                    .foregroundColor(Theme.accentSolid)
                    .padding(.horizontal, 14).padding(.vertical, 5)
                    .background(Theme.bg).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Theme.accentGradient)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: Secondary screens

    @ViewBuilder
    private var secondary: some View {
        switch nav {
        case .add:            AddTimerView(onDismiss: back).environmentObject(store)
        case .edit(let item): AddTimerView(editing: item, onDismiss: back).environmentObject(store)
        case .settings:       SettingsView(onDismiss: back)
        case .list:           EmptyView()
        }
    }

    private func back() { nav = .list }

    // MARK: List

    private var listScreen: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.1))
            if store.timers.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    private var header: some View {
        ZStack {
            Text("Infinity")
                .font(.custom("SnellRoundhand-Bold", size: 20))
                .foregroundColor(.white)
            HStack {
                iconButton("gearshape") { nav = .settings }
                Spacer()
                iconButton("plus") { nav = .add }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func iconButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 28, height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(store.timers) { item in
                    TimerRowView(item: item, onEdit: { nav = .edit(item) })
                        .environmentObject(store)
                    if item.id != store.timers.last?.id {
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 58)
                    }
                }
                .onMove { store.move(from: $0, to: $1) }
            }
        }
        .frame(height: min(CGFloat(store.timers.count) * rowHeight, maxListHeight))
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("∞").font(.system(size: 50, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.15))
            Text("No timers yet").font(.onePlus(13)).foregroundColor(.white.opacity(0.35))
            Button { nav = .add } label: {
                Text("Create one")
                    .font(.onePlus(12, .medium)).foregroundColor(.white)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(Theme.accentGradient).clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 56)
    }
}
