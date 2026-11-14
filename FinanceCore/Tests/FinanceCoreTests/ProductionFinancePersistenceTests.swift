import Foundation
import XCTest
@testable import FinanceCore

final class ProductionFinancePersistenceTests: XCTestCase {
    func testSaveLoadRoundTripInTemporaryDirectory() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ProductionFinancePersistence(
            directory: directory,
            keychainService: FinanceStorage.uiTestNamespace.keychainService
        )
        let assetID = UUID()
        let snapshot = FinancialSnapshot(
            exchangeRateUSDToVND: 26_000,
            assets: [
                FinancialAsset(
                    id: assetID,
                    code: "USD",
                    name: "Dollar",
                    currency: .usd,
                    price: 10,
                    transactions: [
                        UnitTransaction(id: UUID(), occurredAt: Date(timeIntervalSince1970: 1), units: 3)
                    ]
                )
            ]
        )

        try persistence.save(snapshot)
        let loaded = try XCTUnwrap(persistence.load())

        XCTAssertEqual(loaded, snapshot)
        XCTAssertTrue(FileManager.default.fileExists(atPath: persistence.primaryURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: persistence.recoveryURL.path))
    }

    func testCorruptPrimaryFallsBackToRecovery() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ProductionFinancePersistence(
            directory: directory,
            keychainService: ""
        )
        let snapshot = FinancialSnapshot(exchangeRateUSDToVND: 25_500)
        try persistence.save(snapshot)
        try Data("not-json".utf8).write(to: persistence.primaryURL, options: .atomic)

        let loaded = try XCTUnwrap(persistence.load())
        XCTAssertEqual(loaded.exchangeRateUSDToVND, 25_500)
        XCTAssertTrue(FileManager.default.fileExists(atPath: persistence.primaryURL.path))
    }

    func testUnsupportedSchemaVersionIsNotOverwritten() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = ProductionFinancePersistence(
            directory: directory,
            keychainService: ""
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let future = Data(
            """
            {"schemaVersion":999,"exchangeRateUSDToVND":25500,"assets":[]}
            """.utf8
        )
        try future.write(to: persistence.primaryURL, options: .atomic)
        let before = try Data(contentsOf: persistence.primaryURL)

        XCTAssertThrowsError(try persistence.load()) { error in
            XCTAssertEqual(error as? FinancePersistenceError, .unsupportedSchemaVersion(999))
        }
        XCTAssertEqual(try Data(contentsOf: persistence.primaryURL), before)
    }

    func testSaveFailureRollsBackPrimaryAndRecovery() throws {
        let directory = temporaryDirectory()
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: directory.path
            )
            try? FileManager.default.removeItem(at: directory)
        }
        let persistence = ProductionFinancePersistence(
            directory: directory,
            keychainService: ""
        )
        let original = FinancialSnapshot(exchangeRateUSDToVND: 25_500)
        try persistence.save(original)
        let originalPrimary = try Data(contentsOf: persistence.primaryURL)
        let originalRecovery = try Data(contentsOf: persistence.recoveryURL)

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o555],
            ofItemAtPath: directory.path
        )

        let mutated = FinancialSnapshot(exchangeRateUSDToVND: 30_000)
        XCTAssertThrowsError(try persistence.save(mutated))

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: directory.path
        )
        XCTAssertEqual(try Data(contentsOf: persistence.primaryURL), originalPrimary)
        XCTAssertEqual(try Data(contentsOf: persistence.recoveryURL), originalRecovery)
    }

    func testUITestNamespaceUsesEmptyKeychainService() {
        XCTAssertEqual(FinanceStorage.uiTestNamespace.keychainService, "")
        XCTAssertEqual(FinanceStorage.uiTestNamespace.directoryName, "XQFinanceUITests")
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("finance-persistence-\(UUID().uuidString)", isDirectory: true)
    }
}
