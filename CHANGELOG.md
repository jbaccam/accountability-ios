# Changelog

All notable changes to the Accountability iOS app are documented here.
This is the native Swift / SwiftUI app (the canonical client).

## [Unreleased]

### Added
- App Store **privacy manifest** (`PrivacyInfo.xcprivacy`) declaring collected
  data (email, name, photos, precise location, user ID — all linked, none used
  for tracking) and the UserDefaults required-reason API.
- `ITSAppUsesNonExemptEncryption=false` so TestFlight uploads skip the
  export-compliance prompt.
- **Legal docs**: plain-language Privacy Policy, Terms of Service, and a
  Fair Play / Responsible Use policy, hosted in `docs/` and linked in-app.
- Additional unit-test coverage for the `Format` and `Copy` helpers.

### Changed
- Settings legal links now resolve (point at hosted policy docs) instead of the
  placeholder `accountability.app` domain.

## Foundation (native iOS rewrite)

The app was rewritten from React Native to native SwiftUI. Feature set carried
over:

- **Auth** — email/password sign-up with verification, sign-in, password reset,
  resend-confirmation with cooldown; session stored in the iOS Keychain.
- **Challenges** — create, join by invite code, invite friends, daily/weekly/
  custom frequency, photo/caption/location/timestamp proof requirements.
- **Check-ins** — submit proof, peer review/voting, resolve and results.
- **Social** — friends, friend requests, profiles, avatars.
- **Money** — simulated balances only (`REAL_MONEY_ENABLED` is off); explicit
  "not gambling / practice funds" copy throughout.
- **Account** — in-app account deletion (App Store requirement), settings.
- **Polish** — haptics on key actions, VoiceOver labels, Reduce Motion support,
  light/dark theming, monochrome app icon.
- **CI** — GitHub Actions builds an unsigned device IPA on every push.
