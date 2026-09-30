import Foundation

// MARK: - Claude

struct ClaudeUsageResponse: Codable, Sendable {
    var fiveHour: ClaudeWindow?
    var sevenDay: ClaudeWindow?
    var sevenDayOpus: ClaudeWindow?
    var sevenDaySonnet: ClaudeWindow?
    var limits: [ClaudeLimit]?
    var extraUsage: ClaudeExtraUsage?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case sevenDayOpus = "seven_day_opus"
        case sevenDaySonnet = "seven_day_sonnet"
        case limits
        case extraUsage = "extra_usage"
    }
}

struct ClaudeWindow: Codable, Sendable {
    var utilization: Double?
    var resetsAt: String?
    var limitDollars: Double?
    var usedDollars: Double?
    var remainingDollars: Double?

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
        case limitDollars = "limit_dollars"
        case usedDollars = "used_dollars"
        case remainingDollars = "remaining_dollars"
    }
}

struct ClaudeLimit: Codable, Sendable {
    var kind: String?
    var group: String?
    var percent: Double?
    var severity: String?
    var resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case kind, group, percent, severity
        case resetsAt = "resets_at"
    }
}

struct ClaudeExtraUsage: Codable, Sendable {
    var isEnabled: Bool?
    var disabledReason: String?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "is_enabled"
        case disabledReason = "disabled_reason"
    }
}

// MARK: - Codex

struct CodexUsageResponse: Codable, Sendable {
    var planType: String?
    var rateLimit: CodexRateLimit?
    var credits: CodexCredits?
    var resetCredits: CodexResetCredits?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case credits
        case resetCredits = "rate_limit_reset_credits"
    }
}

struct CodexRateLimit: Codable, Sendable {
    var allowed: Bool?
    var limitReached: Bool?
    var primaryWindow: CodexWindow?
    var secondaryWindow: CodexWindow?

    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexWindow: Codable, Sendable {
    var usedPercent: Double?
    var limitWindowSeconds: Int?
    var resetAfterSeconds: Int?
    var resetAt: Int?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }
}

struct CodexCredits: Codable, Sendable {
    var hasCredits: Bool?
    var balance: String?
    var unlimited: Bool?

    enum CodingKeys: String, CodingKey {
        case hasCredits = "has_credits"
        case balance
        case unlimited
    }
}

struct CodexResetCredits: Codable, Sendable {
    var availableCount: Int?

    enum CodingKeys: String, CodingKey {
        case availableCount = "available_count"
    }
}

// MARK: - Combined snapshot for UI

struct UsageSnapshot: Sendable {
    var claude: ClaudeUsageResponse?
    var claudeError: String?
    var codex: CodexUsageResponse?
    var codexError: String?
    var fetchedAt: Date = Date()
}
