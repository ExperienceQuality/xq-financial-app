import SwiftUI

/// Should-fail fixture: View must not call store.send / importSnapshot / use persistence /
/// NavigationLink(destination:) / navigationDestination / sheet(item:) / @EnvironmentObject.
struct FeatureView: View {
    @EnvironmentObject var store: DummyStore

    var body: some View {
        NavigationStack {
            NavigationLink(destination: Text("bad")) {
                Text("Go")
            }
            Button("Send") {
                store.send(.noop)
                _ = try? store.importSnapshot(Data())
                _ = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                _ = ProductionFinancePersistence.self
                _ = PortfolioStore.loadPortfolio()
            }
        }
        .navigationDestination(for: String.self) { _ in Text("dest") }
        .sheet(item: .constant(OptionalSheet.one)) { _ in Text("sheet") }
    }
}

final class DummyStore: ObservableObject {
    enum Action { case noop }
    func send(_ action: Action) {}
    func importSnapshot(_ data: Data) throws {}
    func loadPortfolio() {}
}

enum PortfolioStore {
    static func loadPortfolio() {}
}

enum ProductionFinancePersistence {}

enum OptionalSheet: String, Identifiable {
    case one
    var id: String { rawValue }
}
