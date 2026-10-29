# Campaign links

One tagged link per channel, so installs can be attributed (Phase 0 of #69). The full links of a
live account are in its [`accounts/`](accounts/) file.

```
https://apps.apple.com/app/apple-store/id6759974325?pt=128610953&ct=<channel>&mt=8
https://play.google.com/store/apps/details?id=com.jonaskeller14.bike_setup_tracker&referrer=utm_source%3D<channel>%26utm_medium%3D<medium>
https://jonaskeller14.com/bike_setup_tracker/get?c=<channel>    (smart link; Android medium is always smartlink)
```

- **iOS** results: App Store Connect → App Analytics → Acquisition → Campaigns (by `ct`). Apple only reports a campaign once it has enough users (privacy threshold).
- **Android** results: Play Console → Store listing acquisition → UTM-tagged traffic (by `utm_source`); Firebase records the campaign on `first_open`.
- **Smart link**: phones go straight to their store, tagged with the channel; desktops see both badges, tagged the same way (Phase 5 of #69). Any lowercase id works, but use one from the table so results stay comparable.
- New channel: add a row with a lowercase `kebab-case` id (≤40 chars). `tool/marketing/posts.py` reads this table and builds the links from the templates above.

| Channel | Medium | Used for |
|---|---|---|
| `website` | `web` | jonaskeller14.com landing page badges |
| `website-qr` | `smartlink` | QR code on the landing page (desktop visitors) |
| `github-readme` | `web` | GitHub README badges |
| `yt-bst` | `video` | Bike Setup Tracker channel: walkthrough + channel links |
| `yt-shorts` | `video` | Shorts pinned comments |
| `yt-jk` | `video` | jonaskeller14 channel: descriptions + community posts |
| `ig-bst` | `social` | Bike Setup Tracker bio + stories |
| `ig-jk` | `social` | jonaskeller14 bio |
| `tiktok` | `social` | TikTok bio |
| `strava-club` | `social` | Club description + posts |
| `strava-jk` | `social` | Personal activity posts |
| `strava-directory` | `directory` | Strava app directory listing |
| `reddit-mtb` | `forum` | r/MTB |
| `reddit-mountainbiking` | `forum` | r/mountainbiking |
| `reddit-bikewrench` | `forum` | r/bikewrench |
| `reddit-gravel` | `forum` | r/gravelcycling |
| `reddit-flutterdev` | `forum` | r/FlutterDev (dev angle) |
| `reddit-sideproject` | `forum` | r/SideProject (dev angle) |
| `mtbnews` | `forum` | MTB-News forum (DE) |
| `pinkbike` | `forum` | Pinkbike forum |
| `alternativeto` | `directory` | AlternativeTo listing |
| `flutter-showcase` | `directory` | Flutter showcase / Made with Flutter |
