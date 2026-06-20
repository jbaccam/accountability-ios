# Install on your iPhone from Windows (free Apple ID, no Mac)

This installs the app with **Sideloadly**, which re-signs the build with your free
Apple ID and pushes it to your iPhone over USB. No Mac and no paid Apple Developer
account needed.

**Limitations of a free Apple ID (Apple's rules, not ours):**
- The app **stops opening after 7 days** — just re-run Sideloadly to refresh it.
- Max **3** sideloaded apps on the account at once.
- The iPhone must be plugged into the PC to (re)install.

If you ever want OTA installs with no cable and no 7-day expiry, that requires the
**$99/yr Apple Developer Program** + TestFlight (ask and I'll wire the CI for it).

---

## 1. Get the IPA

Every green CI run publishes one:

1. Go to **https://github.com/jbaccam/accountability-ios/actions**
2. Open the latest successful **iOS Build** run.
3. Under **Artifacts**, download **`Accountability-unsigned-ipa`**.
4. Unzip it — inside is `Accountability-unsigned.ipa`.

## 2. One-time Windows setup

1. Install **iTunes** and **iCloud** from Apple's website (the direct downloads, **not**
   the Microsoft Store versions — Sideloadly needs their USB drivers).
2. Install **Sideloadly**: https://sideloadly.io
3. Plug your iPhone into the PC with a cable, unlock it, and tap **Trust** when asked.

## 3. Install

1. Open Sideloadly.
2. Drag `Accountability-unsigned.ipa` into the **IPA** field.
3. Enter your **Apple ID** (a free one is fine). A throwaway Apple ID is fine too.
4. Click **Start**. Enter your Apple ID password when prompted (use an
   [app-specific password](https://support.apple.com/102654) if you have 2FA).
5. Wait for **"Done"**.

## 4. Trust the app on the iPhone

1. On the iPhone: **Settings -> General -> VPN & Device Management**.
2. Tap your Apple ID under **Developer App**, then **Trust**.
3. iOS 16+: also enable **Settings -> Privacy & Security -> Developer Mode**, then reboot.
4. Launch **Accountability** from your home screen.

## 5. When it expires (every 7 days)

Plug the phone back in, open Sideloadly, and **Start** again with the same IPA. Your
data and login persist (they live in Supabase, not the app bundle).

---

### Notes
- This is a **Debug** build (unsigned, then re-signed by Sideloadly). It talks to the
  same Supabase backend as the original app, so your existing account works.
- If Sideloadly complains the bundle id is taken, let it append a suffix / use its
  "change bundle id" option — free accounts sometimes need a unique id.
