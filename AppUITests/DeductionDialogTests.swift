import XCTest

@MainActor
final class DeductionDialogTests: FinanceUITestCase {
    func testCancelingDeductionKeepsTransaction() {
        let portfolio = PortfolioScreen(application: financeApp)
        portfolio.openAddAsset().add(symbol: "MSFT", name: "Microsoft", startingPrice: "100")
        portfolio.openBuyLotEditor().add(units: "1", price: "100")
        portfolio.transactionRow.requireExistence()

        portfolio.deductFirstTransaction(confirm: false)
        portfolio.transactionRow.requireExistence()
        captureScreenshot(named: "Deduction cancel keeps transaction")
    }
}
