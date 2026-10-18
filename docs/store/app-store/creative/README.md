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
| Layout | Brand row, headline, a block of changed values left; the phone right | Type only: brand row, headline, a row of values in the safe area; rules full width |

- Since [#77](https://github.com/jonaskeller14/bike_setup_tracker/issues/77) Phase 2 the sources
  follow the brand guide (`docs/marketing/brand.md`) and its reference frames; Phase 5 rendered
  the v2 PNGs.
- Safe areas come from Apple's Photoshop templates on
  [asset best practices](https://developer.apple.com/app-store/asset-best-practices/).
  `render_images.py` checks that all text sits inside them; `--safe` also writes each render with
  the overlay to `build/marketing/safe/`. `?lang=de` switches to German.
- The search layout reaches past its safe area. That's accepted: the App Store Connect search
  preview showed the full image, and Apple's own samples do the same. The check uses a 160 px
  margin there and draws Apple's area as a guide.
- No phone on the header: Apple's guidance makes the header about the brand.
- Shared tokens and the phone frame come from `docs/marketing/templates/marketing.css` and
  `template.js`, like every marketing template.
- Screen: the real raw `04_raw.png` (Setup History) in the iPhone frame. Re-render and re-upload
  when it changes.
- PNG, RGB, no transparency. Leave **"use header asset in search results"** off.
- Commit a new render only once it's live in App Store Connect.

| Locale | Headline ([messaging.md](../../../marketing/messaging.md)) |
|---|---|
| en-US | Search: R4 "The logbook for your MTB suspension." · Header: R2 "Fork and shock settings, remembered." |
| de-DE | Search: R4 "Das Logbuch für dein MTB-Fahrwerk." · Header: R2 "Gabel und Dämpfer: kein Klick geht verloren." |

The screens stay English in both locales, like the screenshots, until #18.

**Before upload**, check the App Store Connect preview in light and dark mode, EN and DE, for
cropped text.

## Video variants

`python tool/marketing/build_kit.py appstore` renders both videos, EN + DE, as set in
[`docs/marketing/kits/appstore.json`](../../../../docs/marketing/kits/appstore.json):

| | Search results | Header |
|---|---|---|
| Output | `build/marketing/appstore/search_{en-US,de-DE}.mp4` | `build/marketing/appstore/header_{en-US,de-DE}.mp4` |
| Size | 2880×1920 | 3840×1646 |
| Shows | The `demo_setup_history` recording plays in the phone (`data-video`): history, then the comparison with the setup before and "end of May reference" | Type only, like the still: the values row starts at the old values, `→10`, `→8` and `→85 psi` fade in one by one, then it holds the still's final state and fades back, so it loops |

- Record the demo clips first: `tool/screenshots/run_ios.sh iphone --demo`.
- H.264, 30 fps, 5–30 s, no audio track (search results always play muted, the header by default).
- The search video is 2880×1920 rather than 3840×2560: 3840×2560 is over H.264's largest frame
  size (level 5.2), and 2880×1920 is inside Apple's 3:2 range.
- No bike illustration in the header animation: #77 Phase 1 dropped the drawn bike, so the
  animation shows the brand's own data voice, the changed values.
- The same kit renders the App Store app previews (`docs/store/README.md`, App previews). Videos
  aren't committed; they stay in `build/`.
