# Contributing

Notes for working on the Accountability iOS app.

## Project generation

The `.xcodeproj` is **generated**, not committed — `project.yml` is the source of
truth. After pulling, or after changing files/targets/settings:

```sh
brew install xcodegen        # once
cp Secrets.example.xcconfig Secrets.xcconfig   # once; fill in Supabase values
xcodegen generate
open Accountability.xcodeproj
```

Adding a new source file under an existing source group (`App/`, `Core/`,
`Features/`, …) just requires re-running `xcodegen generate` — there's no project
file to hand-edit.

## Architecture

Plain MV: `@Observable` services in `Services/`, SwiftUI views in `Features/`, one
view per screen. No third-party state framework. See `ARCHITECTURE.md`.

- `Models/` — `Codable` row types + enums; wire strings must match the Postgres
  enums (see `Tests/EnumWireTests`).
- `Core/` — pure helpers (`Format`, `Copy`, `Haptics`). Keep them pure and
  testable.
- `DesignSystem/` — theme tokens + reusable components; use these instead of
  raw colors/spacing.

## Tests

Unit tests live in `Tests/`. Prefer testing pure logic (formatting, decoding,
status mappings). Keep assertions **locale-independent** so they pass on CI.

```sh
xcodebuild test -scheme Accountability -destination 'platform=iOS Simulator,name=iPhone 16'
```

## CI

`.github/workflows/ios.yml` builds an unsigned device IPA on every push/PR
(macOS runner). This is the verification loop — author on any OS, but the build
must stay green. CI falls back to the public Supabase anon values if repo secrets
aren't set.

## Commits

- Conventional-commit prefixes: `feat`, `fix`, `test`, `docs`, `chore`, `perf`.
- Keep the simulated-money framing intact; don't flip `REAL_MONEY_ENABLED`
  without the legal review (see the App Store checklist and COMPLIANCE notes).
- SwiftLint config is in `.swiftlint.yml`.

## Code style

- Swift 5.9, iOS 17+ APIs are fair game.
- Follow the surrounding style; let SwiftLint guide formatting.
