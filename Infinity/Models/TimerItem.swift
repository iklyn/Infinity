import Foundation

// MARK: - Kind

/// The three things this app can track.
enum TimerKind: String, Codable, CaseIterable, Identifiable {
    case timer     = "Timer"      // count down a duration → rings an alarm
    case date      = "Date"       // count down to / up from a specific date
    case progress  = "Progress"   // percent elapsed between two dates

    var id: String { rawValue }

    var defaultEmoji: String {
        switch self {
        case .timer:    return "⏱"
        case .date:     return "📅"
        case .progress: return "📊"
        }
    }
}

enum RepeatOption: String, Codable, CaseIterable, Identifiable {
    case never   = "Never"
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case yearly  = "Yearly"

    var id: String { rawValue }
}

/// How a Date timer expresses its remaining/elapsed time.
enum DisplayUnit: String, Codable, CaseIterable, Identifiable {
    case auto  = "Auto"
    case days  = "Days"
    case years = "Years"

    var id: String { rawValue }
}

// MARK: - TimerItem

struct TimerItem: Identifiable, Codable, Equatable {
    var id           = UUID()
    var name         = ""
    var emoji        = "⏱"
    var kind         = TimerKind.timer
    var startDate    = Date()                                            // progress start / general anchor
    var targetDate   = Date().addingTimeInterval(5 * 60)                 // the moment
    var repeatOption = RepeatOption.never
    var displayUnit  = DisplayUnit.auto
    var isCompleted  = false
    var completedAt: Date? = nil          // when it rang — used to auto-clear after a day
    var createdAt    = Date()

    /// True if this was created counting *down* (a future moment) rather than
    /// counting *up* (a past date such as a birthday). Drives alarm + repeat advance.
    var isCountingDown: Bool { targetDate > createdAt }
}

// MARK: - Sample data (first run)

extension TimerItem {
    static var samples: [TimerItem] {
        let cal  = Calendar.current
        let now  = Date()
        let year = cal.component(.year, from: now)

        return [
            TimerItem(
                name: "New Year \(year + 1)", emoji: "🎆", kind: .date,
                targetDate: cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!,
                repeatOption: .yearly
            ),
            TimerItem(
                name: "My Birthday", emoji: "🎂", kind: .date,
                startDate:  cal.date(from: DateComponents(year: 1995, month: 6, day: 15))!,
                targetDate: cal.date(from: DateComponents(year: 1995, month: 6, day: 15))!,
                repeatOption: .yearly, displayUnit: .years,
                createdAt:  now                                          // < targetDate(1995) → counts up
            ),
            TimerItem(
                name: "\(year) Progress", emoji: "📊", kind: .progress,
                startDate:  cal.date(from: DateComponents(year: year,     month: 1, day: 1))!,
                targetDate: cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
            ),
        ]
    }
}
