import XCTest
@testable import Accountability

/// PostgREST emits a few timestamp shapes; PostgresDate.parse must handle all of
/// them and reject junk. (Used by the JSON decoder's date strategy.)
final class PostgresDateTests: XCTestCase {
    func testParsesFractionalAndPlainISO() {
        XCTAssertNotNil(PostgresDate.parse("2026-06-17T12:30:00.123Z"))
        XCTAssertNotNil(PostgresDate.parse("2026-06-18T09:00:00Z"))
    }

    func testSpaceSeparatedMatchesISOInstant() {
        // "yyyy-MM-dd HH:mm:ss" (UTC) should resolve to the same instant as the
        // equivalent ISO-8601 "...T...Z" string.
        let space = PostgresDate.parse("2026-06-18 09:00:00")
        let iso = PostgresDate.parse("2026-06-18T09:00:00Z")
        XCTAssertNotNil(space)
        XCTAssertEqual(space, iso)
    }

    func testRejectsGarbage() {
        XCTAssertNil(PostgresDate.parse(""))
        XCTAssertNil(PostgresDate.parse("not-a-date"))
    }
}
