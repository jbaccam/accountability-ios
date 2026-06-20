import XCTest
@testable import Accountability

final class FormatTests: XCTestCase {
    func testMoneyDropsTrailingZeros() {
        XCTAssertEqual(Format.money(10), "$10")
        XCTAssertEqual(Format.money(10.5), "$10.50")
        XCTAssertEqual(Format.money(0), "$0")
        XCTAssertEqual(Format.money(1234.99), "$1234.99")
    }

    func testParseMoneyToleratesSeparators() {
        XCTAssertEqual(Format.parseMoney("10,000"), 10000)
        XCTAssertEqual(Format.parseMoney("25"), 25)
        XCTAssertEqual(Format.parseMoney("abc"), 0)
        XCTAssertEqual(Format.parseMoney(""), 0)
    }

    func testCountdown() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertEqual(Format.countdown(deadline: now, now: now), "ended")
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(30 * 60), now: now), "30m left"
        )
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(3 * 3600 + 12 * 60), now: now),
            "3h 12m left"
        )
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(3 * 86400), now: now), "3d left"
        )
    }

    func testFrequency() {
        XCTAssertEqual(Format.frequency(.daily, periodDays: 1), "Daily")
        XCTAssertEqual(Format.frequency(.weekly, periodDays: 7), "Weekly")
        XCTAssertEqual(Format.frequency(.custom, periodDays: 3), "Every 3 days")
    }
}
