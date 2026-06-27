import XCTest
@testable import Accountability

/// Coverage for parseMoney symbol handling and the frequency label rules.
final class FormatEdgeTests: XCTestCase {
    func testMoneyWholeAndDecimal() {
        XCTAssertEqual(Format.money(3), "$3")
        XCTAssertEqual(Format.money(2.9), "$2.90")
        XCTAssertEqual(Format.money(2.99), "$2.99")
        XCTAssertEqual(Format.money(1234.5), "$1234.50")
    }

    func testParseMoneyRejectsCurrencySymbols() {
        // Only commas are stripped; a leading "$" is non-numeric -> 0.
        XCTAssertEqual(Format.parseMoney("$10"), 0)
        XCTAssertEqual(Format.parseMoney("12abc"), 0)
    }

    func testParseMoneyKeepsDecimals() {
        XCTAssertEqual(Format.parseMoney("1,000.50"), 1000.5)
        XCTAssertEqual(Format.parseMoney("3.14"), 3.14)
    }

    func testFrequencyEnumWins() {
        // The .daily enum short-circuits even with a non-1 period.
        XCTAssertEqual(Format.frequency(.daily, periodDays: 5), "Daily")
    }

    func testFrequencyCustomPeriods() {
        XCTAssertEqual(Format.frequency(.custom, periodDays: 1), "Daily")
        XCTAssertEqual(Format.frequency(.custom, periodDays: 7), "Weekly")
        XCTAssertEqual(Format.frequency(.custom, periodDays: 14), "Every 14 days")
    }
}
