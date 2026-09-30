import SwiftUI

@MainActor
final class UsageStore: ObservableObject {
    @Published var snapshot = UsageSnapshot()
    @Published var isLoading = false
    @Published var now = Date()

    private var timer: Timer?
    private var tickCount = 0

    var claude5h: Double? { snapshot.claude?.fiveHour?.utilization }
    var claude7d: Double? { snapshot.claude?.sevenDay?.utilization }
    var codex5h: Double? { snapshot.codex?.rateLimit?.primaryWindow?.usedPercent }
    var codexWeekly: Double? { snapshot.codex?.rateLimit?.secondaryWindow?.usedPercent }

    /// Short menubar text, e.g. "CC 86% · CX 3%"
    var menuTitle: String {
        let cc = claude5h.map { "\(Int($0.rounded()))%" } ?? "–"
        let cx = codex5h.map { "\(Int($0.rounded()))%" } ?? "–"
        return "CC \(cc) · CX \(cx)"
    }

    var hasWarning: Bool {
        (claude5h ?? 0) >= 85 || (codexWeekly ?? 0) >= 90 || (codex5h ?? 0) >= 90
    }

    func start() {
        refresh()
        // Tick every 30s for countdowns; refetch every 5 min to avoid
        // rate-limiting the Claude usage endpoint.
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.now = Date()
                self.tickCount += 1
                if self.tickCount % 10 == 0 { self.refresh() } // 10 * 30s = 5 min
            }
        }
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            let snap = await UsageFetchers.fetchAll()
            self.snapshot = snap
            self.now = Date()
            self.isLoading = false
        }
    }
}

@main
struct UsageMenuApp: App {
    @StateObject private var store = UsageStore()

    var body: some Scene {
        MenuBarExtra {
            MenuView(store: store)
        } label: {
            Label(store.menuTitle, systemImage: store.hasWarning ? "exclamationmark.triangle.fill" : "chart.bar.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
