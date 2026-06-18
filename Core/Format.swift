import Foundation

// Display helpers — port of src/lib/format.ts. Money here is always simulated.

enum Format {
    /// "$10" / "$10.50" — drops a trailing ".00".
    static func money(_ amount: Double) -> String {
        let fixed = String(format: "%.2f", amount)
        return "$" + (fixed.hasSuffix(".00") ? String(fixed.dropLast(3)) : fixed)
    }

    /// Parse a money text field, tolerating thousands separators ("10,000" -> 10000).
    /// Returns 0 for anything non-numeric.
    static func parseMoney(_ text: String) -> Double {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
        return Double(cleaned) ?? 0
    }

    /// "Jun 15"
    static func date(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: d)
    }

    /// "Jun 15, 9:00 PM"
    static func dateTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMdjmm")
        return f.string(from: d)
    }

    /// "3h 12m left" / "2d left" / "ended".
    static func countdown(deadline: Date, now: Date) -> String {
        let ms = deadline.timeIntervalSince(now)
        if ms <= 0 { return "ended" }
        let minutes = Int(ms / 60)
        if minutes < 60 { return "\(minutes)m left" }
        let hours = minutes / 60
        if hours < 48 { return "\(hours)h \(minutes % 60)m left" }
        return "\(hours / 24)d left"
    }

    /// "Daily" / "Weekly" / "Every 3 days".
    static func frequency(_ frequency: ChallengeFrequency, periodDays: Int) -> String {
        if frequency == .daily || periodDays == 1 { return "Daily" }
        if frequency == .weekly || periodDays == 7 { return "Weekly" }
        return "Every \(periodDays) days"
    }

    /// Local-time calendar key, e.g. "2026-06-12".
    static func localDayKey(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// "Mon, Jun 15" for picked dates.
    static func dateFull(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: d)
    }

    /// "HH:MM[:SS]" (DB time column) -> "9:00 PM".
    static func clockTime(_ time: String) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return time }
        var comps = DateComponents()
        comps.year = 2000; comps.month = 1; comps.day = 1
        comps.hour = parts[0]; comps.minute = parts[1]
        guard let d = Calendar.current.date(from: comps) else { return time }
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("jmm")
        return f.string(from: d)
    }

    static func deviceTimezone() -> String {
        TimeZone.current.identifier
    }

    /// Human description of an unknown error (service calls surface these).
    static func errorMessage(_ error: Error) -> String {
        let nsError = error as NSError
        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String,
           !message.isEmpty {
            return message
        }
        return error.localizedDescription
    }
}
