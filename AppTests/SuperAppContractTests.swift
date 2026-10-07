import FinanceCore
import FitnessCore
import XCTest
@testable import ios_xq_finance_app

@MainActor
final class SuperAppContractTests: XCTestCase {
    func testFinanceFailureLeavesFitnessLoadedAndRetryDoesNotReloadFitness() throws {
        var financeAttempts = 0
        var fitnessAttempts = 0
        let fitnessStore = try FitnessStore(persistence: InMemoryFitnessPersistence())
        let model = SuperAppModel(
            financeLoader: {
                financeAttempts += 1
                return .failed("Finance unavailable")
            },
            fitnessLoader: {
                fitnessAttempts += 1
                return .loaded(fitnessStore)
            }
        )

        assertFailure(model.financeState, message: "Finance unavailable")
        assertLoaded(model.fitnessState, identicalTo: fitnessStore)

        model.retryFinance()

        XCTAssertEqual(financeAttempts, 2)
        XCTAssertEqual(fitnessAttempts, 1)
        assertLoaded(model.fitnessState, identicalTo: fitnessStore)
    }

    func testFitnessFailureLeavesFinanceLoadedAndRetryDoesNotReloadFinance() throws {
        var financeAttempts = 0
        var fitnessAttempts = 0
        let financeStore = try FinanceStore(persistence: InMemoryFinancePersistence())
        let model = SuperAppModel(
            financeLoader: {
                financeAttempts += 1
                return .loaded(financeStore)
            },
            fitnessLoader: {
                fitnessAttempts += 1
                return .failed("Fitness unavailable")
            }
        )

        assertLoaded(model.financeState, identicalTo: financeStore)
        assertFailure(model.fitnessState, message: "Fitness unavailable")

        model.retryFitness()

        XCTAssertEqual(financeAttempts, 1)
        XCTAssertEqual(fitnessAttempts, 2)
        assertLoaded(model.financeState, identicalTo: financeStore)
    }

    func testSuperAppAccessibilityIdentifiersAreUniqueAndStable() {
        let identifiers = [
            SuperAppAccessibility.financeTab,
            SuperAppAccessibility.fitnessTab,
            SuperAppAccessibility.financeFailure,
            SuperAppAccessibility.fitnessFailure,
            SuperAppAccessibility.financeRetry,
            SuperAppAccessibility.fitnessRetry,
            SuperAppAccessibility.fitnessImportButton,
            SuperAppAccessibility.fitnessImportStatus
        ]

        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertEqual(SuperAppAccessibility.financeTab, "super-app.tab.finance")
        XCTAssertEqual(SuperAppAccessibility.fitnessTab, "super-app.tab.fitness")
        XCTAssertEqual(SuperAppAccessibility.financeFailure, "super-app.finance.failure")
        XCTAssertEqual(SuperAppAccessibility.fitnessFailure, "super-app.fitness.failure")
        XCTAssertEqual(SuperAppAccessibility.financeRetry, "super-app.finance.retry")
        XCTAssertEqual(SuperAppAccessibility.fitnessRetry, "super-app.fitness.retry")
        XCTAssertEqual(SuperAppAccessibility.fitnessImportButton, "fitness.import.button")
        XCTAssertEqual(SuperAppAccessibility.fitnessImportStatus, "fitness.import.status")
    }

    private func assertFailure<Value>(
        _ state: FeatureBootstrapState<Value>,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .failed(let actualMessage) = state else {
            return XCTFail("Expected failed state", file: file, line: line)
        }
        XCTAssertEqual(actualMessage, message, file: file, line: line)
    }

    private func assertLoaded<Value: AnyObject>(
        _ state: FeatureBootstrapState<Value>,
        identicalTo expected: Value,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .loaded(let actual) = state else {
            return XCTFail("Expected loaded state", file: file, line: line)
        }
        XCTAssertTrue(actual === expected, file: file, line: line)
    }
}
