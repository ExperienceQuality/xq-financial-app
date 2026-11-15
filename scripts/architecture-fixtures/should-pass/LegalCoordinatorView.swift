import SwiftUI

/// Positive control: coordinator container may own navigationDestination + sheet(item:).
struct LegalCoordinatorView: View {
    @Bindable var coordinator: LegalTabCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            Text("Root")
                .navigationDestination(for: LegalRoute.self) { route in
                    Text(String(describing: route))
                }
        }
        .sheet(item: $coordinator.sheet) { destination in
            Text(String(describing: destination))
        }
    }
}

enum LegalRoute: Hashable {
    case detail
}

enum LegalSheet: String, Identifiable {
    case editor
    var id: String { rawValue }
}

@Observable
final class LegalTabCoordinator {
    var path: [LegalRoute] = []
    var sheet: LegalSheet?
}
