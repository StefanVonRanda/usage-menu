import SwiftUI

struct MenuView: View {
    @ObservedObject var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            claudeSection
            Divider()
            codexSection
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 340)
        .onAppear { store.start() }
    }

    private var header: some View {
        HStack {
            Text("Plan Usage")
                .font(.headline)
            Spacer()
            if store.isLoading {
                ProgressView().scaleEffect(0.7)
            } else {
                Button("Refresh") { store.refresh() }
                    .buttonStyle(.link)
            }
        }
    }

    // MARK: - Claude

    private var claudeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Claude Code").font(.subheadline.bold())
                Spacer()
                if let t = store.snapshot.claude?.fiveHour?.resetsAt,
                   let d = TimeFmt.claudeDate(t) {
                    Text("5h reset \(TimeFmt.absolute(d))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if let err = store.snapshot.claudeError {
                Text(err).font(.caption).foregroundStyle(.red)
            } else {
                UsageRow(
                    title: "Session (5h)",
                    percent: store.claude5h,
                    reset: resetTextClaude(store.snapshot.claude?.fiveHour?.resetsAt),
                    now: store.now
                )
                UsageRow(
                    title: "Weekly (7d)",
                    percent: store.claude7d,
                    reset: resetTextClaude(store.snapshot.claude?.sevenDay?.resetsAt),
                    now: store.now
                )
                if let opus = store.snapshot.claude?.sevenDayOpus?.utilization, opus > 0 {
                    UsageRow(
                        title: "Opus weekly",
                        percent: opus,
                        reset: resetTextClaude(store.snapshot.claude?.sevenDayOpus?.resetsAt),
                        now: store.now
                    )
                }
                if let sonnet = store.snapshot.claude?.sevenDaySonnet?.utilization, sonnet > 0 {
                    UsageRow(
                        title: "Sonnet weekly",
                        percent: sonnet,
                        reset: resetTextClaude(store.snapshot.claude?.sevenDaySonnet?.resetsAt),
                        now: store.now
                    )
                }
            }
        }
    }

    private func resetTextClaude(_ iso: String?) -> String {
        guard let iso, let d = TimeFmt.claudeDate(iso) else { return "reset —" }
        return "resets in \(TimeFmt.countdown(to: d, now: store.now)) · \(TimeFmt.absolute(d))"
    }

    // MARK: - Codex

    private var codexSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Codex").font(.subheadline.bold())
                Spacer()
                Text(store.snapshot.codex?.planType?.capitalized ?? "")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let err = store.snapshot.codexError {
                Text(err).font(.caption).foregroundStyle(.red)
            } else {
                let primary = store.snapshot.codex?.rateLimit?.primaryWindow
                let secondary = store.snapshot.codex?.rateLimit?.secondaryWindow
                UsageRow(
                    title: "5-hour",
                    percent: primary?.usedPercent,
                    reset: "resets in \(TimeFmt.countdownUnix(primary?.resetAt, now: store.now)) · \(TimeFmt.absoluteUnix(primary?.resetAt))",
                    now: store.now
                )
                UsageRow(
                    title: "Weekly",
                    percent: secondary?.usedPercent,
                    reset: "resets in \(TimeFmt.countdownUnix(secondary?.resetAt, now: store.now)) · \(TimeFmt.absoluteUnix(secondary?.resetAt))",
                    now: store.now
                )
                if let credits = store.snapshot.codex?.resetCredits?.availableCount {
                    Text("Banked resets available: \(credits)")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if store.snapshot.codex?.rateLimit?.limitReached == true {
                    Text("Limit reached — wait for reset or check Settings → Usage")
                        .font(.caption).foregroundStyle(.orange)
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Updated \(store.snapshot.fetchedAt, style: .relative) ago")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Open Claude Usage") {
                    if let url = URL(string: "https://claude.ai/settings/usage") {
                        NSWorkspace.shared.open(url)
                    }
                }.buttonStyle(.link).font(.caption)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.link).font(.caption)
            }
        }
    }
}

struct UsageRow: View {
    var title: String
    var percent: Double?
    var reset: String
    var now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.caption)
                Spacer()
                Text(TimeFmt.percent(percent)).font(.caption.bold())
            }
            ProgressView(value: (percent ?? 0) / 100)
                .tint(color)
            Text(reset).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private var color: Color {
        guard let p = percent else { return .accentColor }
        if p >= 90 { return .red }
        if p >= 70 { return .orange }
        return .accentColor
    }
}
