# App Store creative assets

Header and search-results assets, Phase 1b of
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69). Uploaded next to the default
product page in App Store Connect and reviewed independently of an app version.

Two separate assets instead of one universal 16:9 asset. Apple's universal template only keeps a
1402×962 box in the upper middle safe on every device, too small for text plus screens; the
product page header got cropped in the App Store Connect preview.

| | Search results (**Suchergebnisse**) | Header (**Kopfzeile**) |
|---|---|---|
| Source | [`search_3x2.html`](search_3x2.html) | [`header_21x9.html`](header_21x9.html) |
| Render | `python tool/marketing/render_images.py appstore-search` | `python tool/marketing/render_images.py appstore-header` |
| Output | `search_{en-US,de-DE}.png`, 3840×2560 | `header_{en-US,de-DE}.png`, 3840×1646 |
| Art safe area | 836, 765, 2168×1030 | 1097, 493, 1646×661 |
| Layout | Icon, name, headline, subline left; two phones right | Headline centered in the safe area; phones at the sides may be cropped |

- Safe areas come from Apple's Photoshop templates on
  [asset best practices](https://developer.apple.com/app-store/asset-best-practices/). `?safe` in
  the URL draws them; `?lang=de` switches to German.
- The search layout reaches past its safe area. That's accepted: the App Store Connect search
  preview showed the full image, and Apple's own samples do the same.
- Shared styles (gradient, colors, phone frame) are in [`creative.css`](creative.css).
- Screens: real raws `03_raw.png` (Add Setup) and `04_raw.png` (Setup History) in the iPhone
  frame. Re-render and re-upload when those raws change.
- PNG, RGB, no transparency. Leave **"use header asset in search results"** off.
- Commit a new render only once it's live in App Store Connect.

| Locale | Headline | Subline (search only) |
|---|---|---|
| en-US | Never Lose Your Suspension Sweet Spot | Log suspension, tire pressure and trail conditions for every ride. |
| de-DE | Nie wieder den Sweet Spot deines Fahrwerks verlieren | Fahrwerk, Reifendruck und Trail-Bedingungen für jede Ausfahrt. |

The screens stay English in both locales, like the screenshots, until #18.

**Before upload**, check the App Store Connect preview in light and dark mode, EN and DE, for
cropped text.
