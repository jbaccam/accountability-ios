# App Store Submission Checklist

The concrete steps to get Accountability from "builds in CI" to "live on
TestFlight / the App Store." Ordered roughly by dependency.

## 0. Prerequisites
- [ ] **Apple Developer Program** membership ($99/yr). Everything below needs it.
- [ ] A Mac with Xcode (for the signed Archive — CI only builds *unsigned*).
- [ ] App record created in **App Store Connect** with bundle ID
      `com.accountability.app`.

## 1. Signing & identifiers
- [ ] Register the App ID `com.accountability.app` in the developer portal.
- [ ] Create a distribution certificate + provisioning profile (or let Xcode
      "Automatically manage signing").
- [ ] Confirm capabilities match usage: Camera, Photo Library, Location When In
      Use (all already declared in `Info.plist`).

## 2. App metadata (App Store Connect)
- [ ] App name, subtitle, category (Health & Fitness or Productivity).
- [ ] Description, keywords, support URL, marketing URL.
- [ ] **Privacy Policy URL** — currently the in-repo `docs/PRIVACY.md`; host on a
      real domain before submission.
- [ ] App Privacy "nutrition label": declare email, name, photos, coarse/precise
      location, user ID — all "linked to you", **not** used for tracking.
      (Mirrors `PrivacyInfo.xcprivacy`.)
- [ ] Age rating questionnaire. While simulated-money: no real-money gambling.

## 3. Assets
- [ ] App icon 1024×1024 (present: `AppIcon.appiconset/icon-1024.png`).
- [ ] Screenshots for required device sizes (6.7" iPhone at minimum).
- [ ] Optional: preview video.

## 4. Build & upload
- [ ] `xcodegen generate`, then Archive in Xcode (Release).
- [ ] Validate, then upload to App Store Connect.
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption=false` is set, so no
      per-upload prompt.

## 5. Review readiness (common rejection causes)
- [ ] **Account deletion** reachable in-app — done (Settings → Danger zone).
- [ ] **Working privacy policy link** — see §2.
- [ ] Demo account credentials provided in App Review notes (reviewers need to
      see past the auth wall).
- [ ] No dead links / placeholder content in-app.
- [ ] All permission prompt strings are clear (they are, in `Info.plist`).

## 6. Money positioning
- [ ] Keep `REAL_MONEY_ENABLED = false` for v1 — ship simulated.
- [ ] Copy consistently says "simulated / practice" (locked by `CopyTests`).
- [ ] Do **not** enable real money or cash prizes without the legal review in
      `COMPLIANCE` (skill-vs-gambling, money transmission, KYC, tax).

## Not blocking submission, but soon
- [ ] Host legal docs on a real domain.
- [ ] Backend sweep for orphaned avatar/proof files after account deletion.
- [ ] Crash/analytics opt-in (if added, update the privacy manifest + label).
