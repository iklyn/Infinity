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
    @State private var fromLeft = false        // direction the secondary screen comes from

    // One constant window height for every screen → screens never resize, so nothing jumps.
    private let windowHeight: CGFloat = 360
    private let spring = Animation.spring(response: 0.5, dampingFraction: 0.9)

    var body: some View {
        ZStack(alignment: .top) {              // top-pinned so the header never drifts
            if nav == .list {
                listScreen
                    .zIndex(1)
                    .transition(.move(edge: fromLeft ? .trailing : .leading))
            }
            if nav.isSecondary {
                secondary
                    .zIndex(2)
                    .transition(.move(edge: fromLeft ? .leading : .trailing))
            }
        }
        .frame(width: 360, height: windowHeight, alignment: .top)
        .background(Theme.bg)
        .animation(spring, value: nav)
        .clipped()
        .overlay(alignment: .top) {
            if store.isAlarming { alarmBanner }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: store.isAlarming)
    }

    /// Navigate, recording which side the new screen should slide in from.
    private func go(_ dest: NavDest, fromLeft: Bool) {
        self.fromLeft = fromLeft
        nav = dest
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        ZStack {
            Text("Infinity")
                .font(.custom("SnellRoundhand-Bold", size: 20))
                .foregroundColor(.white)
            HStack {
                iconButton("gearshape") { go(.settings, fromLeft: true) }   // gear is left → slide from left
                Spacer()
                iconButton("plus") { go(.add, fromLeft: false) }            // plus is right → slide from right
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

    /// Active timers first, completed ones sink to the bottom (stable within each group).
    private var ordered: [TimerItem] {
        store.timers.enumerated()
            .sorted { ($0.element.isCompleted ? 1 : 0, $0.offset)
                    < ($1.element.isCompleted ? 1 : 0, $1.offset) }
            .map(\.element)
    }

    private var list: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(ordered) { item in
                    TimerRowView(item: item, onEdit: { go(.edit(item), fromLeft: false) })
                        .environmentObject(store)
                        .opacity(item.isCompleted ? 0.65 : 1)
                    if item.id != ordered.last?.id {
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 58)
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.timers)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("∞").font(.system(size: 50, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.15))
            Text("No timers yet").font(.onePlus(13)).foregroundColor(.white.opacity(0.35))
            Button { go(.add, fromLeft: false) } label: {
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
