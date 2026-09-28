import Foundation
import XCTest
@testable import FinanceCore

final class LegacyMigrationTests: XCTestCase {
    func testV2MigrationPreservesIdentityDateUnitsAndDiscardsPurchasePrice() throws {
        let assetID = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
        let transactionID = "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
        let data = Data(
            """
            {
              "version": 2,
              "exchangeRateUSDToVND": 26000,
              "assets": [{
                "id": "\(assetID)",
                "symbol": "GOLD",
                "name": "Gold",
                "nativeCurrency": "VND",
                "currentPrice": 100000,
                "transactions": [{
                  "id": "\(transactionID)",
                  "date": "Sep 26, 2026",
                  "units": 2.5,
                  "unitPrice": 75000
                }]
              }]
            }
            """.utf8
        )

        let migrated = try LegacyPortfolioMigrator.migrate(data)

        XCTAssertEqual(migrated.schemaVersion, 3)
        XCTAssertEqual(migrated.exchangeRateUSDToVND, 26_000)
        XCTAssertEqual(migrated.assets.first?.id.uuidString, assetID)
        XCTAssertEqual(migrated.assets.first?.code, "GOLD")
        XCTAssertEqual(migrated.assets.first?.currency, .vnd)
        XCTAssertEqual(migrated.assets.first?.transactions.first?.id.uuidString, transactionID)
        XCTAssertEqual(migrated.assets.first?.transactions.first?.units, 2.5)

        let encoded = try JSONEncoder().encode(migrated)
        XCTAssertNil(String(decoding: encoded, as: UTF8.self).range(of: "unitPrice"))
    }

    func testV1DefaultsCurrencyAndExchangeRate() throws {
        let data = Data(
            """
            {
              "assets": [{
                "id": "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
                "symbol": "AAPL",
                "name": "Apple",
                "currentPrice": 100,
                "transactions": []
              }]
            }
            """.utf8
        )

        let migrated = try LegacyPortfolioMigrator.migrate(data)

        XCTAssertEqual(migrated.exchangeRateUSDToVND, 25_500)
        XCTAssertEqual(migrated.assets.first?.currency, .usd)
    }

    func testInvalidLegacyDateFailsClosed() {
        let data = Data(
            """
            {
              "version": 2,
              "assets": [{
                "id": "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
                "symbol": "A",
                "name": "Asset",
                "nativeCurrency": "USD",
                "currentPrice": 1,
                "transactions": [{
                  "id": "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
                  "date": "not-a-date",
                  "units": 1,
                  "unitPrice": 1
                }]
              }]
            }
            """.utf8
        )

        XCTAssertThrowsError(try LegacyPortfolioMigrator.migrate(data))
    }
}
