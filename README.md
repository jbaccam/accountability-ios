# Accountability — Native iOS

A clean, native **Swift + SwiftUI** rewrite of the Expo "accountability" app: friends
run challenges, stake simulated money, prove check-ins with photos, and the most
consistent win the pot. **Not gambling** — the outcome is fully in the user's control.

The original Expo/React Native app lives in the sibling `accountability/` repo and remains
the canonical reference for product behavior, the Supabase schema, and the design system.

## Stack

- Swift 5.9+, SwiftUI, **iOS 17+**
- [supabase-swift](https://github.com/supabase/supabase-swift) — Auth, PostgREST, Storage
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — the `.xcodeproj` is generated, not committed
- Plain MV architecture: `@Observable` services, no third-party state framework

## Build (requires macOS + Xcode 16)

```sh
brew install xcodegen
cp Secrets.example.xcconfig Secrets.xcconfig   # then fill in your Supabase values
xcodegen generate
open Accountability.xcodeproj
```

> Authored on Windows; **macOS CI is the build verification loop**
> (`.github/workflows/ios.yml`). Set repo secrets `SUPABASE_URL` and
> `SUPABASE_ANON_KEY`, or CI falls back to the public anon values.

## Layout

| Path | Responsibility |
|---|---|
| `App/` | Entry point, Supabase client, Keychain session storage, `SessionStore` |
| `Models/` | `Codable` row types + enums (port of `types.ts`) |
| `Core/` | Formatting & copy helpers |
| `DesignSystem/` | Theme tokens + reusable SwiftUI components |
| `Services/` | One service per Supabase domain (challenges, submissions, friends, profile, storage) |
| `Navigation/` | Type-safe routes + the root tab/stack shell |
| `Features/` | One SwiftUI view per screen, grouped by area |
