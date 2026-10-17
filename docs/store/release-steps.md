# Store release steps (manual)

What to do in the store consoles after `/releaseversion` has built the release. The App Store
labels are from the **German** App Store Connect UI. Texts to paste:

| Text | Source |
|---|---|
| "What's New" | `release-notes/vX.Y.Z+B.md`, per locale (and per store if split) |
| Promotional Text | `<store>/listing/<locale>.md` → `## Promotional Text` |

## App Store Connect

1. [ ] **Apps** → **Bike Setup Tracker** → tab **Vertrieb** → sidebar **iOS-App** → **+**
   (**Version oder Plattform hinzufügen**) → version `X.Y.Z` → **Erstellen**.
2. [ ] Section **Build** → **Build hinzufügen** → pick build `B` (after TestFlight processing).
3. [ ] For each localization (dropdown top right: **Englisch (USA)**, **Deutsch**):
   - [ ] **Neuerungen in dieser Version**: paste the "What's New" text.
   - [ ] **Werbetext**: paste the Promotional Text. App Store Connect clears it for every new version.
4. [ ] Only if they changed in `listing/` for this release: **Beschreibung**, **Schlüsselwörter**,
   **Untertitel**, screenshots. Otherwise they carry over from the last version.
5. [ ] **Sichern** → **Zur Prüfung hinzufügen** → **Zur Prüfung einreichen**.

## Play Console

1. [ ] **Bike Setup Tracker** → **Testen und veröffentlichen** → **Produktion** →
   **Neuen Release erstellen**.
2. [ ] Upload `app-release.aab` (from the GitHub release or `build/app/outputs/bundle/release/`).
3. [ ] **Versionshinweise**: paste the "What's New" text for `en-US` and `de-DE`.
4. [ ] **Weiter** → **Speichern** → **Release-Übersicht** → **Zur Überprüfung senden**.
5. [ ] While a store listing experiment runs (see `play-store/listing/*_B.md`), change nothing on the
   listing itself; release notes are fine.

## Not needed per release

- **Custom product pages** (`app-store/custom-product-pages/`) and the **Kopfzeile** /
  **Suchergebnisse** assets (`app-store/creative/`) aren't tied to a version and stay live.
  Update them only when screenshots, the screens in the creative assets, or the keyword field
  change (see [`app-store/custom-product-pages/README.md`](app-store/custom-product-pages/README.md#when-a-page-needs-an-update)).
- Keywords, subtitle and description: only when `listing/` changed.
