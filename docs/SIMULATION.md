# Simulation Mode (fake money)

The app currently runs on **simulated money only** — practice funds, not real
currency. Nothing is charged, held, or paid out, and nothing can be withdrawn.
This is the safe default for private playtesting with friends while the
real-money legal/compliance work is figured out separately.

There is no feature flag to flip: the iOS app has **no real-money code path at
all**. The "money" you see is the simulated ledger end to end.

## How the fake money flows

1. **Starting balance.** Every new account starts with **1000** simulated dollars
   (the `profiles.simulated_balance` column default in the database). Friends can
   create and join challenges immediately — no deposit required.

2. **Staking.** Creating or joining a challenge commits an `entry_fee` from your
   simulated balance. The app blocks staking more than you have
   (`Simulation.canAfford`, surfaced as the "Exceeds your simulated balance"
   error in Create).

3. **The pot.** A challenge's pot is every joined player's stake combined:
   `Simulation.pot(entryFee:players:)` = `entryFee × players`.

4. **Forfeit.** Missing a required check-in, being eliminated, or leaving a
   challenge forfeits your stake (with an explicit warning before you leave).

5. **Payout.** When a challenge resolves, winners receive a payout from the pot
   (winner-takes-all, or split among winners). Payout amounts are computed by the
   backend and shown as `+$X (simulated)`.

6. **Top up.** The Deposit screen adds practice funds instantly via the
   `simulated_deposit` RPC — handy if a friend burns through their balance during
   testing.

Every balance, pot, stake, and payout in the UI is labeled "simulated" /
"practice funds" (copy centralized in `Core/Copy.swift`, locked by `CopyTests`).

## Backend pieces (Supabase)

- `profiles.simulated_balance` — the ledger balance (default 1000).
- `simulated_transactions` — append-only history (shown in Profile).
- `apply_simulated_transaction(...)` — internal helper that moves simulated funds.
- `simulated_deposit(p_amount)` — top up your own balance.
- `create_challenge`, `join_challenge_by_invite_code`, `respond_challenge_invite`,
  `leave_challenge` — stake/forfeit happen inside these.

## Resetting balances during a playtest

To give everyone a clean slate, an admin can reset balances directly in the DB:

```sql
update public.profiles set simulated_balance = 1000;
```

## Moving to real money later

Real money is a separate, gated effort — see the App Store checklist and the
COMPLIANCE notes. It requires legal review (skill-vs-gambling, money
transmission, KYC, tax) before any funds move. Do not treat simulated mode as a
stepping stone you can quietly flip; it's a deliberate, standalone product state.
