import FinanceCore
import FitnessCore
import Foundation
import Observation
import SwiftUI
import UIKit

@main
struct XQFinanceApp: App {
    @State private var model = SuperAppModel()

    var body: some Scene {
        WindowGroup {
            SuperAppRootView(model: model)
        }
    }
}

enum SuperAppTab: Hashable {
    case finance
    case fitness
}

enum FeatureBootstrapState<Value> {
    case loading
    case loaded(Value)
    case failed(String)
}

@MainActor
@Observable
final class SuperAppModel {
    typealias FinanceLoader = () -> FeatureBootstrapState<FinanceStore>
    typealias FitnessLoader = () -> FeatureBootstrapState<FitnessStore>

    private(set) var financeState: FeatureBootstrapState<FinanceStore> = .loading
    private(set) var fitnessState: FeatureBootstrapState<FitnessStore> = .loading

    private let financeLoader: FinanceLoader
    private let fitnessLoader: FitnessLoader

    init(
        financeLoader: @escaping FinanceLoader = { FinanceBootstrap.make() },
        fitnessLoader: @escaping FitnessLoader = { FitnessBootstrap.make() },
        loadImmediately: Bool = true
    ) {
        self.financeLoader = financeLoader
        self.fitnessLoader = fitnessLoader

        if loadImmediately {
            retryFinance()
            retryFitness()
        }
    }

    func retryFinance() {
        financeState = .loading
        financeState = financeLoader()
    }

    func retryFitness() {
        fitnessState = .loading
        fitnessState = fitnessLoader()
    }
}

struct SuperAppRootView: View {
    let model: SuperAppModel
    @State private var selectedTab = SuperAppTab.finance

    var body: some View {
        TabView(selection: $selectedTab) {
            FinanceFeatureView(
                state: model.financeState,
                retry: model.retryFinance
            )
            .tabItem {
                Label("Finance", systemImage: "chart.pie.fill")
                    .accessibilityIdentifier(SuperAppAccessibility.financeTab)
            }
            .tag(SuperAppTab.finance)

            FitnessFeatureView(
                state: model.fitnessState,
                retry: model.retryFitness
            )
            .tabItem {
                Label("Fitness", systemImage: "figure.strengthtraining.traditional")
                    .accessibilityIdentifier(SuperAppAccessibility.fitnessTab)
            }
            .tag(SuperAppTab.fitness)
        }
        .tint(XQPalette.ink)
        .background(TabBarAccessibilityBridge())
    }
}

private struct TabBarAccessibilityBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> TabBarAccessibilityView {
        TabBarAccessibilityView()
    }

    func updateUIView(_ view: TabBarAccessibilityView, context: Context) {
        view.applyIdentifiers()
    }
}

private final class TabBarAccessibilityView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            self?.applyIdentifiers()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyIdentifiers()
    }

    func applyIdentifiers() {
        guard let tabBar = window?.firstDescendant(of: UITabBar.self),
              let items = tabBar.items,
              items.count >= 2 else {
            return
        }

        items[0].accessibilityIdentifier = SuperAppAccessibility.financeTab
        items[1].accessibilityIdentifier = SuperAppAccessibility.fitnessTab

        // SwiftUI's `.accessibilityIdentifier` on a `.tabItem` is applied to
        // the tab item model, but UIKit exposes the actual tappable tab as a
        // private `UITabBarButton` descendant. Set identifiers on those
        // controls as well so UI tests and assistive technologies see the
        // stable identity of the element users tap.
        for button in tabBar.descendants().compactMap({ $0 as? UIControl }) {
            switch button.accessibilityLabel {
            case "Finance":
                button.accessibilityIdentifier = SuperAppAccessibility.financeTab
            case "Fitness":
                button.accessibilityIdentifier = SuperAppAccessibility.fitnessTab
            default:
                break
            }
        }
    }
}

private extension UIView {
    func descendants() -> [UIView] {
        subviews + subviews.flatMap { $0.descendants() }
    }

    func firstDescendant<View: UIView>(of type: View.Type) -> View? {
        if let match = self as? View {
            return match
        }

        for subview in subviews {
            if let match = subview.firstDescendant(of: type) {
                return match
            }
        }

        return nil
    }
}

private struct FinanceFeatureView: View {
    let state: FeatureBootstrapState<FinanceStore>
    let retry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView("Loading Finance")
        case .loaded(let store):
            AssetModelRootView(store: store)
        case .failed(let message):
            BootstrapFailureView(
                title: "Financial Data Unavailable",
                message: message,
                failureIdentifier: SuperAppAccessibility.financeFailure,
                retryIdentifier: SuperAppAccessibility.financeRetry,
                retry: retry
            )
        }
    }
}

private struct FitnessFeatureView: View {
    let state: FeatureBootstrapState<FitnessStore>
    let retry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            ProgressView("Loading Fitness")
        case .loaded(let store):
            FitnessRootView(store: store)
        case .failed(let message):
            BootstrapFailureView(
                title: "Fitness Data Unavailable",
                message: message,
                failureIdentifier: SuperAppAccessibility.fitnessFailure,
                retryIdentifier: SuperAppAccessibility.fitnessRetry,
                retry: retry
            )
        }
    }
}

private struct BootstrapFailureView: View {
    let title: String
    let message: String
    let failureIdentifier: String
    let retryIdentifier: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(retryIdentifier)
        }
        .padding()
        .accessibilityIdentifier(failureIdentifier)
    }
}

enum FinanceBootstrap {
    static func make(
        arguments: [String] = CommandLine.arguments,
        fileManager: FileManager = .default
    ) -> FeatureBootstrapState<FinanceStore> {
        do {
            guard let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                return .failed("Application Support is unavailable on this device.")
            }
            let namespace = FinanceStorage.namespace(arguments: arguments)
            let directory = FinanceStorage.directory(
                baseURL: applicationSupport,
                namespace: namespace
            )
            try FinanceStorage.resetUITestDataIfRequested(
                directory: directory,
                namespace: namespace,
                arguments: arguments,
                fileManager: fileManager
            )
            let persistence = ProductionFinancePersistence(
                directory: directory,
                keychainService: namespace.keychainService,
                fileManager: fileManager
            )
            return .loaded(try FinanceStore(persistence: persistence))
        } catch {
            return .failed(error.bootstrapMessage)
        }
    }
}

enum FitnessBootstrap {
    static func make(
        arguments: [String] = CommandLine.arguments,
        fileManager: FileManager = .default
    ) -> FeatureBootstrapState<FitnessStore> {
        do {
            guard let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first else {
                return .failed("Application Support is unavailable on this device.")
            }
            let directory = FitnessStorage.directory(
                baseURL: applicationSupport,
                arguments: arguments
            )
            try FitnessStorage.resetUITestDataIfRequested(
                directory: directory,
                arguments: arguments,
                fileManager: fileManager
            )
            let persistence = JSONFitnessPersistence(
                directory: directory,
                fileSystem: LocalFitnessFileSystem(fileManager: fileManager)
            )
            return .loaded(try FitnessStore(persistence: persistence))
        } catch {
            return .failed(error.bootstrapMessage)
        }
    }
}

private extension Error {
    var bootstrapMessage: String {
        (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}
