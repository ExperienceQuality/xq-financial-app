import Foundation

/// Internal deep-link hook only (D4 / ADR-8). Not wired to URL schemes.
enum AppRoute: Hashable {
    case finance(FinanceRoute)
    case fitness(FitnessRoute)
}

/// Live finance is sheet-only today — no NavigationStack push destinations (T2).
/// `portfolio` names the tab root for `AppRoute` / tests only; it is not pushed.
enum FinanceRoute: Hashable {
    case portfolio
}
