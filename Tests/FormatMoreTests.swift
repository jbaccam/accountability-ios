import XCTest
@testable import Accountability

/// Extra edge-case coverage for the formatting helpers.
final class FormatMoreTests: XCTestCase {
    func testMoneyNegativeAndLarge() {
        XCTAssertEqual(Format.money(-5), "$-5.00")
        XCTAssertEqual(Format.money(1000000), "$1000000")
        XCTAssertEqual(Format.money(0.5), "$0.50")
    }

    func testParseMoneyTrimsAndIgnoresSymbols() {
        XCTAssertEqual(Format.parseMoney("1,250.75"), 1250.75)
        XCTAssertEqual(Format.parseMoney("0"), 0)
        XCTAssertEqual(Format.parseMoney("  "), 0)
    }

    func testCountdownBoundaries() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        // Exactly 60 minutes -> hours branch.
        XCTAssertEqual(Format.countdown(deadline: now.addingTimeInterval(3600), now: now), "1h 0m left")
        // 47h59m still in the hours branch (under 48h).
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(47 * 3600 + 59 * 60), now: now),
            "47h 59m left"
        )
    }

    func testLocalDayKeyShape() {
        // Build a known local date and check the key matches YYYY-MM-DD.
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 9
        let date = Calendar.current.date(from: comps)!
        XCTAssertEqual(Format.localDayKey(date), "2026-06-09")
    }
}
