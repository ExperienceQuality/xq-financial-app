import SwiftUI
import UniformTypeIdentifiers

/// Positive control: coordinator container may own navigationDestination, sheet(item:),
/// fullScreenCover(item:), and fileImporter(.
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
        .fullScreenCover(item: $coordinator.cover) { destination in
            Text(String(describing: destination))
        }
        .fileImporter(
            isPresented: $coordinator.isImporting,
            allowedContentTypes: [.json],
            onCompletion: { _ in }
        )
    }
}

enum LegalRoute: Hashable {
    case detail
}

enum LegalSheet: String, Identifiable {
    case editor
    var id: String { rawValue }
}

enum LegalCover: String, Identifiable {
    case importer
    var id: String { rawValue }
}

@Observable
final class LegalTabCoordinator {
    var path: [LegalRoute] = []
    var sheet: LegalSheet?
    var cover: LegalCover?
    var isImporting = false
}
