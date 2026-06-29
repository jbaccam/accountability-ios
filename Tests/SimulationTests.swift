import XCTest
@testable import Accountability

/// Pure simulated-money math. Deterministic; no real money involved.
final class SimulationTests: XCTestCase {
    func testPot() {
        XCTAssertEqual(Simulation.pot(entryFee: 25, players: 4), 100)
        XCTAssertEqual(Simulation.pot(entryFee: 10.5, players: 3), 31.5)
    }

    func testPotZeroPlayersIsZero() {
        XCTAssertEqual(Simulation.pot(entryFee: 25, players: 0), 0)
        XCTAssertEqual(Simulation.pot(entryFee: 25, players: -1), 0)
    }

    func testPayoutPerWinner() {
        XCTAssertEqual(Simulation.payoutPerWinner(pot: 100, winners: 1), 100) // winner-takes-all
        XCTAssertEqual(Simulation.payoutPerWinner(pot: 100, winners: 4), 25)  // even split
    }

    func testPayoutNoWinnersIsZero() {
        XCTAssertEqual(Simulation.payoutPerWinner(pot: 100, winners: 0), 0)
    }

    func testCanAfford() {
        XCTAssertTrue(Simulation.canAfford(stake: 25, balance: 1000))
        XCTAssertTrue(Simulation.canAfford(stake: 1000, balance: 1000)) // exact balance is fine
        XCTAssertFalse(Simulation.canAfford(stake: 1001, balance: 1000))
    }
}
