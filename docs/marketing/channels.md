# Channel rules

Posting rules per channel for the content kits (Phase 4 of
[#69](https://github.com/jonaskeller14/bike_setup_tracker/issues/69)). Post drafts live in
`kits/<kit>.posts.md`. `build_kit.py` renders them into `POST.md` and fails if a post breaks a
limit below. Rules were checked on **2026-10-15**; re-check a channel's rules before its first post
and when a post gets removed.

## Rules for every channel

- **Disclose that you're the developer** in the first lines of every Reddit and forum post.
- Post manually from your own account. No second accounts, no bots, no automated replies. Claude
  drafts replies; you post them.
- **Each community gets its own wording.** Identical text across subreddits reads as spam and
  trips Reddit's filters.
- **Store links are always campaign links** from [`links.md`](links.md); `build_kit.py` rejects
  any other App Store or Play link. Bios use the smart link
  `jonaskeller14.com/bike_setup_tracker/get?c=<channel>`, which goes live with Phase 5. Post
  nothing that uses it before then.
- **Only state what release builds do.** No presets, ratings, pressure check, riders or bookmarks
  (debug-only). Tasks, the calendar and setup tags are user toggles under Settings → Features; say
  so when a post leans on them.
- Strava: "connects with Strava" / "Strava Sync". Never suggest that Strava endorses the app
  (Strava brand guidelines).
- No numbers from `metrics/` in any post.
- Space launch posts **2–3 days apart**, and stay about 1 h after a Reddit or forum post to answer.
- Don't post in competitors' threads. Answer older "how do you track your settings?" threads only
  where the app really fits.

## Length limits (enforced)

`tool/marketing/posts.py` checks these per field. The platform comes from the channel id
(`reddit-*`, `yt-*`, `ig-*`, `tiktok`).

| Platform | Field | Limit | Notes |
|---|---|---|---|
| Reddit | Title | 300 | |
| Reddit | Body | 40,000 | |
| YouTube | Title | 100 | About 60 characters show in search. No `<` or `>` in titles or descriptions. |
| YouTube | Description | 5,000 | Over 60 hashtags per video: YouTube ignores all of them (checked) |
| YouTube | Tags | 500 | Comma-separated, commas count |
| YouTube | Post (community) | 5,000 | Up to 10 images |
| Instagram | Bio | 150 | The link goes in the separate "Links" field |
| Instagram | Caption | 2,200 | About 125 characters show before "more". **≤5 hashtags** (checked; limit since late 2025) |
| TikTok | Bio | 80 | |
| TikTok | Caption | 2,200 | Some sources say 4,000; 2,200 is safe. About 100 characters show in the feed |

The forums, Strava and the directories have no limits that matter for these posts.

## YouTube

| | Bike Setup Tracker channel (`yt-bst`, `yt-shorts`) | jonaskeller14 channel (`yt-jk`) |
|---|---|---|
| Language | English | English |
| Format | Walkthrough (16:9) with chapters; Shorts (9:16, ≤3 min; the kit's are ≤60 s) | One community image post (carousel, ≤10 images) |
| Links | Clickable in long-form descriptions. **Not clickable in Shorts descriptions**: set the walkthrough as each Short's related video and name the app to search for. | Clickable in the post text |
| Hashtags | 2–4 per video; YouTube shows up to 3 of them next to the title | — |
| Scheduling | YouTube Studio, natively | — |

- **Walkthrough description template:** the `yt-bst` section of `kits/launch.posts.md`. It pulls in
  the app version and the chapter timestamps on every build. For a new release kit, copy that
  section and update the "What you can do" list.
- Chapters need a first chapter at 0:00, at least 3 chapters, and ≥10 s per chapter.
  `build_kit.py` checks the length.
- Music: the kit's track is Content ID registered. Dispute a claim with the license (see
  `tool/marketing/README.md`).

## Instagram

| | Bike Setup Tracker (`ig-bst`) | jonaskeller14 (`ig-jk`) |
|---|---|---|
| Language | English | — |
| Format | Reels (9:16), one pinned carousel, stories from the carousel | Bio update only |
| Links | Not clickable in captions ("Link in bio"). Bio "Links" field and story link stickers are clickable | Bio "Links" field |
| Hashtags | ≤5 per post, specific beats generic (#mtbsetup over #bike) | — |
| Scheduling | Meta Business Suite | — |

## TikTok (`tiktok`)

- English, the same 9:16 videos as the Reels, captions with ≤5 hashtags.
- A clickable bio link needs a **Business account** or 1,000 followers. A Business account
  only limits TikTok's own music library; the kit videos bring their own licensed track.
- Scheduling: TikTok web uploader.

## Reddit

Reddit blocks automated access to its pages, so the subreddits' written rules couldn't be read
directly. Summaries from [Thread Otter](https://www.threadotter.com/subreddit-rules/mtb) (checked
Aug–Oct 2026) are listed below. **Before each post: read the sidebar rules (2 min), then send the
modmail below. Post only after an OK.**

| Sub (channel) | Language | Self-promotion (summary) | Angle and format |
|---|---|---|---|
| r/MTB (`reddit-mtb`) | EN | No clear written position, so it's enforced by removals. Treat as "ask first". | Suspension logbook. Image post with plain screens (raws), not the framed marketing images. |
| r/mountainbiking (`reddit-mountainbiking`) | EN | Only with mod permission or in designated threads. Rewards casual first-person posts. | "My notes app wasn't cutting it". GIF of the setup history. |
| r/gravelcycling (`reddit-gravel`) | EN | Only with mod permission. Commercial links get removed. | Tire pressure per ride and conditions. GIF of adding a setup. |
| r/bikewrench (`reddit-bikewrench`) | EN | No clear written position. The community is repair help: practical, humble, technical. | Service intervals, asked as a real question. **Lowest fit; post last.** |
| r/FlutterDev (`reddit-flutterdev`) | EN | No clear written position. Short, technical posts do well; promotional language doesn't. | Dev angle: Maestro + ffmpeg + headless Chrome pipeline. Check the flair list. |
| r/SideProject (`reddit-sideproject`) | EN | Self-promotion is the point of the sub, but bare link drops get removed. Space reposts ≥2 weeks. | What, why, stack, what I learned, with screenshots. |

- Put links at the end of the body. New or low-karma accounts posting links trip automated
  removal, so a few genuine comments in the sub beforehand help.
- Reply to every comment in the first hour. Critical comments get a thank-you and a concrete answer.

Modmail (adapt the angle line per sub):

```text
Hi mods, I'm the developer of Bike Setup Tracker, a free iOS/Android logbook for suspension and tire pressure settings (no account, no ads; an optional paid Strava sync is the only paid part). Would a one-time post about it be OK here, clearly disclosed as my own app and asking for feedback? Happy to follow any format you prefer. Thanks!
```

## Forums

### MTB-News (`mtbnews`), German

- **Rules:** the [moderation rules](https://www.mtb-news.de/forum/t/moderationsregeln-mtb-news-de.88311/)
  forbid advertising for websites, companies or commercial offers, but "inviting others to visit
  your website now and then is completely fine" as long as advertising isn't the majority of a
  member's posts.
- **Precedent:** developers who presented a free app in **Tech Talk → "Elektronik rund ums Bike"**
  and asked for feedback were received constructively (2016). Marketing-style copy in the same
  subforum was called out as spam (2014).
- So: one thread in "Elektronik rund ums Bike", developer disclosed, a feedback question instead
  of a pitch, and a note that the app UI is still English. Plain text (BBCode editor, no Markdown).
  Attach the forum header and 2–3 GIFs.

### Pinkbike (`pinkbike`): ⛔ not allowed

- Pinkbike's [Community Forum Rules & Guidelines](https://help.pinkbike.com/hc/en-us/articles/35303534427543-Community-Forum-Rules-Guidelines)
  (summary from search results, because the page blocks automated access): self-promotion of
  your own business, product or website is allowed only in designated areas such as Buy & Sell,
  and soliciting posts in the forums are deleted.
- No post is drafted. Decide in #69 whether the channel is dropped.

## Strava

| Channel | Format | Notes |
|---|---|---|
| `strava-club` | Club description + a first post | Club: [strava.com/clubs/bike_setup_tracker](https://www.strava.com/clubs/bike_setup_tracker) |
| `strava-jk` | One line in the description of a real ride | Only on rides where the setup was logged in the app |
| `strava-directory` | Email to developers@strava.com with the client ID (193047) and screenshots | Listing is at Strava's discretion |

## Directories

| Channel | Where | Notes |
|---|---|---|
| `alternativeto` | AlternativeTo | Suggest the app only as an alternative to apps it really replaces |
| `flutter-showcase` | "It's All Widgets!" (Made with Flutter) | Links the public repo |
| `github-readme` | Repo README | Phase 6 commit: feature GIFs and store badges |
