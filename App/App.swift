import FinanceCore
import SwiftUI

@main
struct XQFinanceApp: App {
    private let bootstrap = FinanceBootstrap.make()

    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .loaded(let store):
                AssetModelRootView(store: store)
            case .failed(let message):
                ContentUnavailableView(
                    "Financial Data Unavailable",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text(message)
                )
                .padding()
                .accessibilityIdentifier(FinanceAccessibility.dataUnavailable)
            }
        }
    }
}

private enum FinanceBootstrap {
    case loaded(FinanceStore)
    case failed(String)

    static func make(
        arguments: [String] = CommandLine.arguments,
        fileManager: FileManager = .default
    ) -> FinanceBootstrap {
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
            return .failed((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }
}
