import AppKit

extension Notification.Name {
    static let infinityAlarmStarted = Notification.Name("infinityAlarmStarted")
    static let infinityAlarmStopped = Notification.Name("infinityAlarmStopped")
}

final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    private let fileName = "alarm"        // alarm.mp3 in Resources
    private var sound: NSSound?
    private var alarmUntil = Date.distantPast
    private(set) var isAlarming = false

    /// One-shot preview (Settings).
    func preview() {
        sound?.stop()
        sound = load()
        sound?.play()
    }

    /// Completion alarm — repeats for 30 s so it actually gets noticed.
    func playAlarm() {
        isAlarming = true
        alarmUntil = Date().addingTimeInterval(30)
        NotificationCenter.default.post(name: .infinityAlarmStarted, object: nil)
        loop()
    }

    private func loop() {
        guard Date() < alarmUntil, let s = load() else {
            isAlarming = false
            NotificationCenter.default.post(name: .infinityAlarmStopped, object: nil)
            return
        }
        sound = s
        s.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + max(s.duration, 1) + 0.2) { [weak self] in
            self?.loop()
        }
    }

    func stop() {
        isAlarming = false
        alarmUntil = .distantPast
        sound?.stop()
    }

    private func load() -> NSSound? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else { return nil }
        return NSSound(contentsOf: url, byReference: true)
    }
}
