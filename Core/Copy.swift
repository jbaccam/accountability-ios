import Foundation

// Centralized user-facing copy for money/trust language so the simulated nature
// of balances stays consistent everywhere. Port of src/lib/copy.ts.
//
// TODO(real-payments): all of this copy must be revisited alongside
// legal/compliance/app-store review before any real-money functionality.

enum Copy {
    static let trustDisclaimer = """
    This app works best with people you trust. Group members are responsible \
    for honest submissions and fair reviews. Do not join pools with people \
    you do not trust.
    """

    static let simulatedBalanceNote = """
    Balances are simulated for the MVP. No real money is charged, held, or \
    paid out, and nothing can be withdrawn.
    """

    static let simulatedPotLabel = "Simulated pot"
    static let simulatedBalanceLabel = "Simulated balance"
}
