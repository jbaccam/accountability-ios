# Architecture

A small, layered SwiftUI app. Each layer depends only on the ones above it, so a
file can be understood without reading the whole tree.

```
App/          @main entry, Supabase client, Keychain session, SessionStore
   v
Models/       Codable row types + enums (the wire shapes)
Core/         Pure helpers — Format, Copy, Media, Haptics
   v
DesignSystem/ Theme tokens + reusable components (no business logic)
Services/     One type per Supabase domain (challenges, submissions, friends, profile)
   v
Navigation/   Type-safe Route enum + the root tab/stack shell
Features/     One SwiftUI view per screen, grouped by area
```

## Principles

- **MV, not MVVM/TCA.** Views read state from `@Observable` stores/services via the
  environment. No view-model ceremony, no third-party state framework.
- **Services are stateless** `enum`s of `static async throws` functions that wrap the
  Supabase client. They speak in Models; they never touch SwiftUI.
- **The design system owns all styling.** Screens compose `Screen`, `Card`,
  `AppButton`, etc. and read `@Environment(\.theme)`. No screen hard-codes a color,
  font, or radius — those live in `DesignSystem/`.
- **Navigation is type-safe.** Push destinations are `Route` cases resolved in one
  place (`RouteDestination`); screens push via the `Nav` environment object.
- **Motion is restrained** (see the original `DESIGN.md`): ease-out timing only, no
  springs, transform/opacity only, and animations respect Reduce Motion.

## Data flow

1. A screen calls a `Service` in `.task { }`.
2. The service calls Supabase (PostgREST / RPC / Storage) and decodes into Models.
3. The screen renders from `@State`; auth/session state comes from `SessionStore`.
4. Writes go back through services; `SessionStore.refreshProfile()` re-pulls the user.

## Where things live

| Need to… | Look in |
|---|---|
| Change a color/spacing/type token | `DesignSystem/Colors.swift`, `Layout.swift`, `Typography.swift` |
| Add/﻿modify a reusable control | `DesignSystem/Components/` |
| Add a backend call | `Services/` (match the RPC names in the Expo app's `src/lib/services`) |
| Add a screen | `Features/<area>/`, plus a `Route` case if it's pushed |
| Touch auth/session | `App/SessionStore.swift` |

See `README.md` for build/CI and `SIDELOAD.md` for installing on a device.
