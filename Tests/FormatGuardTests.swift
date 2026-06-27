import XCTest
@testable import Accountability

/// Locale-independent guard-path coverage: malformed clock strings pass through
/// unchanged, and countdown bucketing is exercised at its boundaries.
final class FormatGuardTests: XCTestCase {
    func testClockTimeReturnsInputWhenMalformed() {
        XCTAssertEqual(Format.clockTime(""), "")
        XCTAssertEqual(Format.clockTime("notime"), "notime")
        XCTAssertEqual(Format.clockTime("9"), "9")        // needs at least HH:MM
        XCTAssertEqual(Format.clockTime("ab:cd"), "ab:cd") // non-numeric parts
    }

    func testCountdownMinuteBucket() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        XCTAssertEqual(Format.countdown(deadline: now, now: now), "ended")
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(-60), now: now), "ended"
        )
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(59 * 60), now: now), "59m left"
        )
    }

    func testCountdownHourAndDayBuckets() {
        let now = Date(timeIntervalSince1970: 3_000_000)
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(90 * 60), now: now), "1h 30m left"
        )
        // 48h flips into the day bucket.
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(48 * 3600), now: now), "2d left"
        )
        XCTAssertEqual(
            Format.countdown(deadline: now.addingTimeInterval(49 * 3600), now: now), "2d left"
        )
    }
}
