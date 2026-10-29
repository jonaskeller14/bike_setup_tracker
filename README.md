# Bike Setup Tracker

*Component setup tracker for mountain bikers & road cyclists. Log and forget!*

[![Flutter Test Check](https://github.com/jonaskeller14/bike_setup_tracker/actions/workflows/flutter_test.yml/badge.svg)](https://github.com/jonaskeller14/bike_setup_tracker/actions)
[![codecov](https://codecov.io/gh/jonaskeller14/bike_setup_tracker/graph/badge.svg)](https://codecov.io/gh/jonaskeller14/bike_setup_tracker)
[![License: All Rights Reserved](https://img.shields.io/badge/License-All_Rights_Reserved-red.svg)](LICENSE)
[![Play Store Downloads](https://playbadges.pavi2410.com/badge/downloads?id=com.jonaskeller14.bike_setup_tracker&pretty)](https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker&referrer=utm_source%3Dgithub-readme%26utm_medium%3Dweb)
[![Play Store Ratings](https://playbadges.pavi2410.com/badge/ratings?id=com.jonaskeller14.bike_setup_tracker&pretty)](https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker&referrer=utm_source%3Dgithub-readme%26utm_medium%3Dweb)

<p align="left">
  <a href='https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker&referrer=utm_source%3Dgithub-readme%26utm_medium%3Dweb'>
    <img alt='Get it on Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png' style="width: 155px; vertical-align: middle;"/>
  </a>
  <a href="https://apps.apple.com/app/apple-store/id6759974325?pt=128610953&ct=github-readme&mt=8">
    <img src="https://toolbox.marketingtools.apple.com/api/v2/badges/download-on-the-app-store/black/en-us?releaseDate=1772755200" alt="Download on the App Store" style="width: 120px; vertical-align: middle;"/>
  </a>
</p>

Stop guessing your settings. Start tracking.

Do you keep your suspension clicks, tire pressures, and geometry settings scattered across a messy notes app? Do you struggle to remember exactly which setup felt perfect on that rainy day in the bike park last season?

Bike Setup Tracker is the ultimate digital logbook for cyclists, mechanics, and racers who want to get the most out of their equipment. Whether you are a Downhill racer, an Enduro enthusiast, or a Road cyclist, this app brings professional structure to your bike adjustments.

- [Roadmap](#roadmap)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Screenshots](#screenshots)
  - [Phone](#phone)
  - [Tablet](#tablet)


## Roadmap

Here are the current development goals and their status:

- [x] Publish for **Android** ➡️ **Live on Play Store**
- [x] **Cloud sync** (Google Drive, Android only) ➡️ **Experimental since v1.0.6**
- [x] **Strava** integration to use activity data as context ➡️ **Optional subscription**
- [x] Publish for **iOS** ➡️ **Live on App Store**
- [x] Migration to **drift SQL database**
- [x] **Task Manager** to plan & track service, rides, testing and more ➡️ **Opt-in, now with recurring tasks**
- [x] **Attachments** to add images & files to setups, bikes, components and tasks ➡️ **Opt-in, stored on-device**
- [x] Add a **rider profile** (track body weight, ...) ➡️ **Opt-in**
- [x] **Sub-components**: infinitely deep component hierarchy, Strava stats inherited from the parent ➡️ **Live, opt-in**
- [x] Add **URL support for bike/components** ➡️ **URLs are recognized in notes**
- [x] **Component & task presets** for the most common forks and shocks ➡️ **Live since v1.6.4**
- [ ] **Rating procedure** to distinguish good setups from bad ➡️ **In development**
- [ ] **Marketing** push to grow the user base ➡️ **In progress**
- [ ] **Multiple languages** ➡️ **Planned**

I am open for feedback, suggestions, and bug reports—please feel free to open a new issue for any of these.


## Architecture

| Area | Stack |
|---|---|
| **App** | Flutter / Dart for iOS and Android from one codebase. Provider for state management, Drift (SQLite) as an offline-first local database with versioned migrations, feature flags for staged rollouts |
| **Backend** | Firebase: Cloud Functions (Node.js), Firestore, Auth, App Check, Cloud Messaging, Crashlytics and Analytics. Powers the Strava sync and the server-validated in-app subscriptions |
| **Testing** | Unit, widget and golden tests (Alchemist), CI on GitHub Actions with Codecov coverage reports |
| **Screenshot automation** | Store screenshots captured from a seeded demo app with Maestro flows and rendered into store frames from an HTML template |
| **Deployment** | Store listings, release notes and screenshots versioned in the repo and uploaded via `asc` (App Store) and fastlane (Google Play) |
| **Marketing** | Campaign planning plus a scripted content factory that renders social media images and videos |


## Key Features

🚲 **Manage Your Garage:** Add as many bikes as you want to your virtual garage. Whether you have a gravel bike, a dedicated downhill rig, or a cross-country racer, keep them all organized in one place.

🔧 **Fully Customizable Components:** No two bikes are the same. Create custom components with the specific adjustments you need to track.
- **Suspension:** Track Air Pressure (PSI), Rebound clicks, Compression (HSC/LSC), and Volume Spacers (Tokens).
- **Tires:** Log pressures (PSI/Bar) and compounds.
- **Cockpit:** Note saddle height, bar roll, and lever angles.
- **Frame:** Track flip-chip positions or geometry adjustments.
- **Flexible Inputs:** Use sliders, toggle switches, dropdown menus, or number fields to match the real-world adjustment dials on your bike.

🌤️ **Automatic Weather & Location Context:** Context is everything. When you create a new setup, the app automatically fetches the current weather, temperature, and location.
- Was the trail dry and dusty?
- Was it a wet and muddy race run?
- Now you can correlate your settings with the actual trail conditions.

📝 **Setup History & Evolution:** Never lose a good setup again. Browse your detailed history to see exactly what you changed and when. Compare your current setup to previous sessions (e.g., "Finale Ligure Trip" vs. "Local Trails").

📊 **Strava Integration** *(optional subscription)*: Connect Strava to see which setup you ran on every ride — automatically linked by date and gear. Activity start points and saved setups appear together on a map, so you can revisit what worked at a spot.

🔒 **Your Data, Your Ownership**: Your settings are stored locally or in your private cloud. We have zero access to your data.
- Free Forever: The core app will remain free, so you’ll always have access to your setup history.
- Total Portability: Export your data at any time — you are never locked in.

### Who is this for?
- **Mountain Bikers (MTB):** Find the sweet spot on complex suspension systems.
- **Road & Gravel Cyclists:** Precise tracking for tire pressures and fit adjustments.
- **Racers:** Maintain a professional-grade log of race-day tunes and baseline settings.

Ditch the notebook. Download Bike Setup Tracker and tune your ride with precision.


## Screenshots

### Phone

#### Android (Play Store)
<p align="center">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/01.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/02.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/03.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/04.png" width="23%">
  <br>
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/05.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/06.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/07.png" width="23%">
  <img src="docs/store/play-store/metadata/en-US/images/phoneScreenshots/08.png" width="23%">
</p>

#### iOS (App Store - iPhone 17 Pro Max)
<p align="center">
  <img src="docs/store/app-store/screenshots/en-US/iphone_01.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_02.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_03.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_04.png" width="23%">
  <br>
  <img src="docs/store/app-store/screenshots/en-US/iphone_05.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_06.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_07.png" width="23%">
  <img src="docs/store/app-store/screenshots/en-US/iphone_08.png" width="23%">
</p>

### Tablet

#### Android (Play Store - 10")
<p align="center">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/01.png" width="31%">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/02.png" width="31%">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/03.png" width="31%">
  <br>
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/04.png" width="31%">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/05.png" width="31%">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/06.png" width="31%">
  <br>
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/07.png" width="31%">
  <img src="docs/store/play-store/metadata/en-US/images/tenInchScreenshots/08.png" width="31%">
</p>

#### iOS (App Store - iPad Pro 13")
<p align="center">
  <img src="docs/store/app-store/screenshots/en-US/ipad_01.png" width="31%">
  <img src="docs/store/app-store/screenshots/en-US/ipad_02.png" width="31%">
  <img src="docs/store/app-store/screenshots/en-US/ipad_03.png" width="31%">
  <br>
  <img src="docs/store/app-store/screenshots/en-US/ipad_04.png" width="31%">
  <img src="docs/store/app-store/screenshots/en-US/ipad_05.png" width="31%">
  <img src="docs/store/app-store/screenshots/en-US/ipad_06.png" width="31%">
  <br>
  <img src="docs/store/app-store/screenshots/en-US/ipad_07.png" width="31%">
  <img src="docs/store/app-store/screenshots/en-US/ipad_08.png" width="31%">
</p>

## ⚖️ License & Contributions
This project is All Rights Reserved.

**Review:** You are welcome to review the source code for educational or evaluation purposes.

**Developers:** Feel free to fork and submit Pull Requests! I love collaborating on code improvements.

**Restriction:** You may not publish this app or use its branding (logos/icons) as your own.
