import Foundation

// MARK: - TimeDisplay

struct TimeDisplay {
    var primary  = ""        // "211" / "2:45" / "31" / "42"
    var unit     = ""        // "Days" / "min" / "years" / "%"
    var subtitle = ""        // "Yearly · 1 Jan 2027 · left"
    var progress: Double?    // 0–1 for the ring; nil = none
    var isToday  = false
    var isDone   = false
}

// MARK: - Bounds

let infinityMaxDate: Date = Calendar.current.date(
    from: DateComponents(year: 2099, month: 6, day: 3, hour: 23, minute: 59, second: 59)
)!

/// Far past so birthdays / anniversaries can be entered (counts up as age).
let infinityMinDate: Date = Calendar.current.date(
    from: DateComponents(year: 1900, month: 1, day: 1)
)!

private let yearSeconds = 365.25 * 86_400

// MARK: - TimeCalculator

enum TimeCalculator {

    static func display(for item: TimerItem, now: Date = Date()) -> TimeDisplay {
        switch item.kind {
        case .progress:
            return progress(item, now)
        case .timer, .date:
            return item.targetDate > now
                ? countdown(item, now)
                : countUp(item, now)
        }
    }

    // MARK: Countdown (timer or future date)

    private static func countdown(_ item: TimerItem, _ now: Date) -> TimeDisplay {
        let diff = item.targetDate.timeIntervalSince(now)
        let (value, unit) = format(remaining: diff, item: item)
        return TimeDisplay(primary: value, unit: unit,
                           subtitle: subtitle(item, "left"),
                           progress: ringProgress(item, now))
    }

    // MARK: Count up (past date — age, anniversary)

    private static func countUp(_ item: TimerItem, _ now: Date) -> TimeDisplay {
        let elapsed = now.timeIntervalSince(item.targetDate)
        let years   = elapsed / yearSeconds
        let days    = Int(elapsed / 86_400)

        let useYears = item.displayUnit == .years
            || (item.displayUnit == .auto && elapsed >= yearSeconds)

        if useYears {
            let fmt = years >= 10 ? "%.0f" : "%.1f"
            return TimeDisplay(primary: String(format: fmt, years), unit: "years",
                               subtitle: subtitle(item, "\(days) days"),
                               progress: years - years.rounded(.down))
        }
        return TimeDisplay(primary: "\(days)", unit: days == 1 ? "day" : "days",
                           subtitle: subtitle(item, "ago"),
                           progress: nil)
    }

    // MARK: Progress (% between two dates)

    private static func progress(_ item: TimerItem, _ now: Date) -> TimeDisplay {
        let total = item.targetDate.timeIntervalSince(item.startDate)
        guard total > 0 else { return TimeDisplay(primary: "0", unit: "%") }
        let pct = max(0, min(1, now.timeIntervalSince(item.startDate) / total))
        let dTotal = Int(total / 86_400)
        let dDone  = min(dTotal, max(0, Int(now.timeIntervalSince(item.startDate) / 86_400)))
        return TimeDisplay(primary: String(format: "%.0f", pct * 100), unit: "%",
                           subtitle: "\(dDone) / \(dTotal) days",
                           progress: pct)
    }

    // MARK: Remaining formatter (seconds → years)

    /// Returns the value + unit for a remaining interval, choosing a sensible scale.
    private static func format(remaining diff: TimeInterval, item: TimerItem) -> (String, String) {
        // Explicit override for date timers
        if item.kind == .date {
            switch item.displayUnit {
            case .days:  return ("\(Int(diff / 86_400))", "days")
            case .years: return (String(format: diff / yearSeconds >= 10 ? "%.1f" : "%.2f",
                                        diff / yearSeconds), "years")
            case .auto:  break
            }
        }

        if diff < 60 {
            return ("\(Int(diff))", "sec")
        }
        if diff < 3_600 {
            let m = Int(diff / 60), s = Int(diff.truncatingRemainder(dividingBy: 60))
            return (String(format: "%d:%02d", m, s), "min")
        }
        if diff < 86_400 {
            let h = Int(diff / 3_600), m = Int(diff.truncatingRemainder(dividingBy: 3_600) / 60)
            return (String(format: "%d:%02d", h, m), "hr")
        }
        if diff < yearSeconds {
            let d = Int(diff / 86_400)
            return ("\(d)", d == 1 ? "day" : "days")
        }
        let y = diff / yearSeconds
        return (String(format: y >= 10 ? "%.1f" : "%.2f", y), "years")
    }

    // MARK: Ring progress (created → target)

    private static func ringProgress(_ item: TimerItem, _ now: Date) -> Double? {
        let span = item.targetDate.timeIntervalSince(item.createdAt)
        guard span > 0 else { return nil }
        return max(0, min(1, now.timeIntervalSince(item.createdAt) / span))
    }

    // MARK: Subtitle

    private static func subtitle(_ item: TimerItem, _ hint: String) -> String {
        var parts: [String] = []
        if item.repeatOption != .never { parts.append(item.repeatOption.rawValue) }
        if item.kind != .timer         { parts.append(shortDate(item.targetDate)) }
        if !hint.isEmpty                { parts.append(hint) }
        return parts.joined(separator: " · ")
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f.string(from: date)
    }
}
