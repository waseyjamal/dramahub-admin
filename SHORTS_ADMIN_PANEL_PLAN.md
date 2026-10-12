# Admin Panel — Shorts Page Plan

> Status: **PLAN — waiting for owner approval. No code written yet.**
> App side: `C:\Projects\drama_hub` (branch `feature/shorts`), see `SHORTS_CHECKLIST.md` and `SHORTS_UPLOAD_GUIDE.md` there.
> Data side: `dramahub-data/shorts/{config.json, feed.json, series/<id>.json}` (already pushed, disabled).

## 1. How the admin app works today (investigated)
- Flutter web app with GetX. It reads and writes JSON in `waseyjamal/dramahub-data` through the GitHub API:
  `GitHubRepository.fetchJsonList(path)` / `commitJsonList(path, data, message)`, which handles conflicts and creates missing files.
- Pages are switched by index in `views/layouts/main_layout.dart`, and the menu lives in `views/widgets/sidebar.dart`.
- Existing pages: Dashboard, Dramas, Episodes, Config, Ad Manager.

## 2. ⚠ Problem found: the Ad Manager would erase the Shorts ad keys
`controllers/ad_controller.dart` only keeps the **fixed list** of screen keys in `interstitialScreens` and
`rewardedScreens` (lines ~57–100). When it loads, it ignores unknown keys (`if (containsKey(k))`), and when it saves,
it writes only that fixed list.
So if you add `"shorts_feed": true` to `ad_config.json` by hand, **the next save from the Ad Manager deletes it**.

**Fix (part of this plan, tiny):** add `'shorts_feed': false` to `interstitialScreens` and
`'shorts_unlock': false` to `rewardedScreens`. They then appear as normal toggles in the Ad Manager.
Until this is done, don't add those keys by hand.

## 3. What the new "Shorts" page will do

### Tab 1: Settings (`shorts/config.json`)
- Shorts **on/off** switch
- Free episodes default, max players (3 normal / 2 low-RAM)
- Ads: interstitial on/off, every N episodes, first-after N; rewarded unlock on/off, episodes per ad, unlock-if-no-ad
- `data_version` is **increased automatically** on every Shorts save, so users get updates within seconds

### Tab 2: Series (`shorts/series/*.json` + `feed.json`)
- A list of all series: poster, title, episode count, free count, and whether it's shown in the feed
- **Add series** form: id (auto-made from the title, lowercase_with_underscores), title, description, genre, tags, poster URL,
  free episodes, **video type (HLS or MP4)**, **URL pattern** with `{n}` (pre-filled:
  `https://cdn.dramahubs.stream/shorts/<id>/ep-{n}/index.m3u8`), and episode count. This replaces the command-line generator.
- **Add new episodes** button: "add up to episode 85" generates the missing episodes from the pattern. Existing ones are not touched.
- **Edit an episode**: title, URL, lock/unlock override, delete
- **Test URL** button: checks that the poster and episode 1 URL respond (HTTP 200) before saving, to catch typos
- **Show in feed** toggle plus **reorder** (up/down) to control the Shorts tab order
- **Delete series**: asks for confirmation, removes it from the feed and deletes the file

### Safety rules
- Every save goes through the existing `commitJsonList` (retry, conflict handling, cache invalidation)
- Validation before saving: unique id, at least one episode, valid URLs, no duplicate episode numbers
- The `feed.json` entry is rebuilt from the series file, so title, poster and episode count never get out of sync
- Commit messages are prefixed `Shorts:` so they're easy to find in the history

## 4. Files

New (all under `lib/`):
```
controllers/shorts_controller.dart
views/pages/shorts_manager_page.dart
views/widgets/forms/shorts_series_form_dialog.dart
views/widgets/forms/shorts_episode_form_dialog.dart
```
Existing (small edits, each listed for approval):
| File | Change |
|---|---|
| `views/layouts/main_layout.dart` | add `ShortsManagerPage()` to the pages list |
| `views/widgets/sidebar.dart` | add a "Shorts" menu item |
| `app/bindings.dart` | register `ShortsController` (lazy) |
| `controllers/ad_controller.dart` | add the 2 screen keys (§2) |

No changes to the Drama/Episode/Config logic. No new packages.

## 5. Steps & checklist
- [ ] P0 Owner approves this plan; commit/clean the admin repo (`dramahub-data` submodule shows as modified)
- [ ] P1 Ad controller fix (§2) + verify Ad Manager still saves correctly
- [ ] P2 `ShortsController`: load/save config, list series, add/edit/delete series and episodes, feed sync, auto data_version
- [ ] P3 Shorts page: Settings tab
- [ ] P4 Shorts page: Series tab + forms + URL test + reorder
- [ ] P5 Menu + layout wiring
- [ ] P6 Verify: `flutter analyze` 0 new issues, `flutter build web` succeeds
- [ ] P7 Owner test: create a test series → check the JSON in GitHub → check the app shows it → delete it

## 6. Open questions
1. Is it OK to fix `ad_controller.dart` as in §2? (Without it, Shorts ads can't be controlled from the panel.)
2. Episode thumbnails: per-episode URL pattern too (optional), or only the series poster? (Plan: optional pattern field.)
3. How do you deploy the admin panel (Firebase hosting?), so I can give you the exact steps after the build?
