import Foundation

enum TimeFmt {
    /// "2026-09-30T20:00:00.218938+00:00" -> Date
    static func claudeDate(_ iso: String?) -> Date? {
        guard let iso, !iso.isEmpty else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: iso) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        return f2.date(from: iso)
    }

    static func countdown(to date: Date?, now: Date = Date()) -> String {
        guard let date else { return "—" }
        let secs = Int(date.timeIntervalSince(now))
        if secs <= 0 { return "resetting…" }
        let h = secs / 3600, m = (secs % 3600) / 60
        if h >= 24 {
            let d = h / 24
            return "\(d)d \(h % 24)h"
        }
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(secs)s"
    }

    static func countdownUnix(_ unix: Int?, now: Date = Date()) -> String {
        guard let unix else { return "—" }
        return countdown(to: Date(timeIntervalSince1970: TimeInterval(unix)), now: now)
    }

    static func absolute(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: date)
    }

    static func absoluteUnix(_ unix: Int?) -> String {
        guard let unix else { return "—" }
        return absolute(Date(timeIntervalSince1970: TimeInterval(unix)))
    }

    static func percent(_ v: Double?) -> String {
        guard let v else { return "—" }
        return "\(Int(v.rounded()))%"
    }
}
