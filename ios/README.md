# Heather for iPhone and iPad

A SwiftUI app that runs the Heather web app **bundled inside it** (works offline) in a WKWebView, plus native extras:

- **Daily reminder** (local notification; Settings → Daily reminder)
- **Haptics** on right/wrong answers and wins
- **iOS share sheet** for invites
- **Invite links open the app** (universal links for `heather-delta.vercel.app/?join=…`)
- Text messages, Facebook, Privacy and Help open outside the app
- In the app: no Stripe/Garden Club page (App Store rule 3.1.1), no placeholder video ad (rule 2.1); "Get 5 more moves" is free

Needs Xcode 16 or newer (Xcode 26 recommended; App Store uploads need the current SDK). Minimum iOS 16.

## Run it

1. Open `ios/Heather.xcodeproj` in Xcode.
2. Click the **Heather** project → **Heather** target → **Signing & Capabilities** → choose your **Team** (needs the Apple Developer Program, $99 US/year, to put it on the App Store; a free Apple ID works for running on your own phone).
3. If Xcode says the bundle ID is taken, change `com.aidenjenner.heather` to something unique.
4. Pick an iPhone simulator (or your phone) and press **Run** (⌘R).

## After changing the web app

```sh
python3 build.py          # rebuild index.html from src/template.html
./ios/sync-web.sh         # copy it (and words.json, privacy, help pages) into the app
```
Then build again in Xcode. The website updates on every push; the app only updates when you submit a new version.

## Invite links opening the app (universal links)

Once you have your Apple **Team ID** (developer.apple.com → Membership), the website needs a file at
`https://heather-delta.vercel.app/.well-known/apple-app-site-association`:

```json
{ "applinks": { "details": [ { "appIDs": ["TEAMID.com.aidenjenner.heather"], "components": [ { "?": { "join": "?*" } } ] } ] } }
```
Ask Claude to add it with your Team ID (it also needs a `Content-Type: application/json` header in `vercel.json`).

## Files

| File | What it does |
|---|---|
| `Heather/HeatherApp.swift` | App entry; full-screen web view, light/dark status bar, handles invite links |
| `Heather/WebModel.swift` | Sets up the web view, keeps game pages inside the app, opens other links outside |
| `Heather/BundleSchemeHandler.swift` | Serves the bundled web files at `heather://app/…` |
| `Heather/NativeBridge.swift` | Haptics, share sheet, daily reminder |
| `Heather/Web/` | The web app (copied by `sync-web.sh`) |
| `Heather/PrivacyInfo.xcprivacy` | Privacy manifest: no tracking; name + family questions for app functionality only |
| `Heather/Info.plist` | Launch screen (night background + sprig) |
| `Heather.entitlements` | Associated domain for invite links |
| `Heather/Assets.xcassets` | App icon (1024, no transparency), colours, launch logo |
