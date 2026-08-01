import XCTest
@testable import ios_xq_finance_app

final class AssetDeckNavigationTests: XCTestCase {
    func testSwipeDirectionsMoveInOppositeOrder() {
        // Three-asset ring: left advances, right retreats.
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 0, direction: .left, count: 3),
            1
        )
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 1, direction: .right, count: 3),
            0
        )
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 0, direction: .right, count: 3),
            2
        )
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 2, direction: .left, count: 3),
            0
        )
    }

    func testSingleAssetStaysAtZero() {
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 0, direction: .left, count: 1),
            0
        )
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 0, direction: .right, count: 1),
            0
        )
    }

    func testEmptyDeckReturnsZero() {
        XCTAssertEqual(
            AssetDeckNavigation.index(after: 0, direction: .left, count: 0),
            0
        )
    }
}
