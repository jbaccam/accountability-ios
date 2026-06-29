# Running a fake-money playtest with friends

How to get the app into your friends' hands and run a real challenge on
simulated money. The app is simulation-only right now (see
[SIMULATION.md](./SIMULATION.md)) — perfect for a low-stakes private test.

## Getting the app onto phones

There are two paths. Pick based on whether you have a paid Apple account.

### Option A — Sideload (free, fiddly, good for 2-3 people)
Each tester installs the unsigned IPA themselves with Sideloadly. Full steps in
[../SIDELOAD.md](../SIDELOAD.md). Caveats they need to know up front:
- The app **stops opening after 7 days**; they re-run Sideloadly to refresh it.
- It needs a PC with iTunes/iCloud drivers and a USB cable each install.
- Their data/login persist (everything lives in Supabase, not the app).

This works but is a real ask for non-technical friends.

### Option B — TestFlight (smooth, needs $99/yr Apple Developer)
With the Apple Developer Program you upload one build and invite testers by email
or a public link — they install the TestFlight app and tap "Install." No cables,
no 7-day expiry, up to 10,000 testers. This is the right path for a real
playtest; ask and the CI can be wired to upload to TestFlight automatically.
See [APP-STORE-CHECKLIST.md](./APP-STORE-CHECKLIST.md).

## Set expectations with testers

Tell everyone, clearly:
- **The money is fake.** Everyone starts with 1000 simulated dollars. Nothing is
  charged and nothing pays out for real — it's practice money to make the
  challenge feel real.
- Be honest with check-ins and fair with reviews — challenges run on trust.
- It's an early build; bugs and rough edges are expected, and that's the point.

## Suggested first challenge

Keep the first one short and easy to verify so you exercise the whole loop:
- **Daily, 5-7 days**, photo proof required.
- A modest stake (e.g. 50) so eliminations actually sting a little.
- 3-5 people. Small enough to stay engaged, big enough for a real pot.

This runs the full flow: create -> invite by code -> join (stake) ->
daily check-in with photo -> peer review -> elimination/forfeit -> results &
payout.

## During the test

- Share the **invite code** from the challenge screen so friends can join.
- If someone runs their balance down, they can top up on the **Deposit** screen.
- Watch for: confusing copy, anywhere the fake-money framing is unclear, broken
  photo uploads, review/voting confusion, and the results screen accuracy.

## Resetting between tests

To give everyone a clean 1000 again, run in the Supabase SQL editor:

```sql
update public.profiles set simulated_balance = 1000;
```

## Collecting feedback

Keep it lightweight — a group chat thread or a shared note. The two questions
that matter most: *did people actually check in for the whole challenge?* and
*did the social pressure make them stick?* Those tell you if the core idea works,
long before real money is on the table.
