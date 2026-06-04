import Foundation
import Combine

final class TimerStore: ObservableObject {
    @Published var timers: [TimerItem] = []
    @Published var isAlarming = false

    private var ticker: Timer?
    private let storageKey = "infinity.timers.v3"

    init() {
        load()
        startTicker()
        // Reset when the alarm finishes on its own (30 s elapsed).
        NotificationCenter.default.addObserver(
            forName: .infinityAlarmStopped, object: nil, queue: .main
        ) { [weak self] _ in self?.isAlarming = false }
    }

    deinit { ticker?.invalidate() }

    /// Silence a ringing alarm (called from the Stop button, Esc, or menu-bar click).
    func stopAlarm() {
        SoundManager.shared.stop()
        isAlarming = false
    }

    // MARK: - CRUD

    func add(_ item: TimerItem)    { timers.append(item); save() }
    func delete(_ item: TimerItem) { timers.removeAll { $0.id == item.id }; save() }

    func update(_ item: TimerItem) {
        guard let i = timers.firstIndex(where: { $0.id == item.id }) else { return }
        timers[i] = item; save()
    }

    func move(from source: IndexSet, to destination: Int) {
        timers.move(fromOffsets: source, toOffset: destination); save()
    }

    // MARK: - Persistence

    func save() {
        guard let data = try? JSONEncoder().encode(timers) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TimerItem].self, from: data) {
            timers = decoded
        } else {
            timers = TimerItem.samples
        }
    }

    // MARK: - Ticking

    private func startTicker() {
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func tick() {
        objectWillChange.send()      // refresh the live values every second
        advanceRepeats()
        fireCompletions()
    }

    /// Move passed recurring countdowns to their next occurrence.
    private func advanceRepeats() {
        let now = Date()
        var changed = false
        for i in timers.indices where
            timers[i].kind != .progress &&
            timers[i].repeatOption != .never &&
            timers[i].isCountingDown &&
            timers[i].targetDate < now {
            advance(&timers[i].targetDate, by: timers[i].repeatOption, until: now)
            timers[i].isCompleted = false
            changed = true
        }
        if changed { save() }
    }

    private func advance(_ date: inout Date, by opt: RepeatOption, until now: Date) {
        var comps = DateComponents()
        switch opt {
        case .daily:   comps.day = 1
        case .weekly:  comps.weekOfYear = 1
        case .monthly: comps.month = 1
        case .yearly:  comps.year = 1
        case .never:   return
        }
        while date < now {
            guard let next = Calendar.current.date(byAdding: comps, to: date) else { break }
            date = next
        }
    }

    /// Ring the alarm when a one-shot countdown reaches zero.
    private func fireCompletions() {
        let now = Date()
        var changed = false
        for i in timers.indices where
            timers[i].kind != .progress &&
            timers[i].repeatOption == .never &&
            timers[i].isCountingDown &&
            timers[i].targetDate <= now &&
            !timers[i].isCompleted {
            timers[i].isCompleted = true
            changed = true
            SoundManager.shared.playAlarm()
            isAlarming = true
        }
        if changed { save() }
    }
}
