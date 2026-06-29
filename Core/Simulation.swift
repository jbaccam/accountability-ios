import Foundation

/// Pure money math for the **simulated** economy. All amounts are practice funds
/// (see Copy.simulatedBalanceNote); no real money is involved. Centralized so the
/// pot/affordability rules live in one tested place instead of inline in views.
///
/// New accounts start with a simulated balance (currently 1000, set by the
/// `profiles.simulated_balance` column default in the database).
enum Simulation {
    /// The simulated pot: every joined player's stake combined.
    static func pot(entryFee: Double, players: Int) -> Double {
        guard players > 0 else { return 0 }
        return entryFee * Double(players)
    }

    /// What each winner receives if the pot is split evenly among them.
    /// (winner_takes_all is just the one-winner case.)
    static func payoutPerWinner(pot: Double, winners: Int) -> Double {
        guard winners > 0 else { return 0 }
        return pot / Double(winners)
    }

    /// Whether a stake fits within the player's simulated balance.
    static func canAfford(stake: Double, balance: Double) -> Bool {
        stake <= balance
    }
}
